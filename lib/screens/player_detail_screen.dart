import 'package:flutter/material.dart';

import '../main.dart' show notifyFavoritesChanged, bravesRed, bravesNavy;
import '../models/player.dart';
import '../models/player_stats.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

/// Shows one player in detail and lets the user save them (with a personal
/// note) to the local SQLite favorites — the API ↔ storage bridge.
class PlayerDetailScreen extends StatefulWidget {
  final Player player;
  final ApiService api;
  const PlayerDetailScreen({
    super.key,
    required this.player,
    required this.api,
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  final _db = DatabaseHelper.instance;
  late Player _player = widget.player;
  final _noteController = TextEditingController();

  bool _loadingDetails = true;
  bool _detailsFailed = false;
  bool _isFavorite = false;

  // Live season/career stats.
  bool _loadingStats = true;
  bool _statsFailed = false;
  PlayerStats? _stats;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _isFavorite = await _db.isFavorite(_player.id);
    // If already saved, preload any existing note from the DB.
    if (_isFavorite) {
      final favs = await _db.getFavorites();
      final existing = favs.where((p) => p.id == _player.id).toList();
      if (existing.isNotEmpty) _noteController.text = existing.first.note;
    }
    if (mounted) setState(() {});
    await _loadDetails();
    await _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _statsFailed = false;
    });
    try {
      final stats = await widget.api.fetchPlayerStats(_player);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingStats = false;
        _statsFailed = true;
      });
    }
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loadingDetails = true;
      _detailsFailed = false;
    });
    try {
      final detailed = await widget.api.fetchPlayerDetails(_player);
      if (!mounted) return;
      setState(() {
        _player = detailed;
        _loadingDetails = false;
      });
    } catch (_) {
      // Non-fatal: fall back to roster-level info.
      if (!mounted) return;
      setState(() {
        _loadingDetails = false;
        _detailsFailed = true;
      });
    }
  }

  Future<void> _save() async {
    await _db.savePlayer(
      _player.copyWith(
        note: _noteController.text.trim(),
        savedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    setState(() => _isFavorite = true);
    notifyFavoritesChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Saved ${_player.fullName} to favorites')),
      );
  }

  Future<void> _remove() async {
    await _db.deletePlayer(_player.id);
    setState(() => _isFavorite = false);
    notifyFavoritesChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Removed ${_player.fullName} from favorites')),
      );
  }

  /// Live stats card: a compact, color-accented panel with a Braves gradient
  /// header and a tight stat grid. Handles loading / retry / empty inline.
  Widget _buildStatsSection() {
    final title = _stats == null
        ? 'Live Stats'
        : '${_stats!.season} ${_stats!.isPitcher ? "Pitching" : "Hitting"}';

    Widget content;
    if (_loadingStats) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_statsFailed) {
      content = Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _loadStats,
          icon: const Icon(Icons.refresh),
          label: const Text('Couldn’t load stats — Retry'),
        ),
      );
    } else if (_stats == null || _stats!.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No stats available for this player yet.'),
      );
    } else {
      content = GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
        padding: const EdgeInsets.all(12),
        children: [
          for (final line in _stats!.lines)
            _StatTile(label: line.key, value: line.value),
        ],
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bravesNavy.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Braves-colored header strip.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [bravesNavy, bravesRed],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          // For loading/retry/empty states, give the message some padding;
          // the grid brings its own.
          if (_loadingStats || _statsFailed || _stats == null || _stats!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: content,
            )
          else
            content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_player.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 64,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundImage: NetworkImage(_player.headshotUrl),
              child: const Icon(Icons.person, size: 48),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _player.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          Center(
            child: Text(
              '#${_player.jerseyNumber} · ${_player.position}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 20),

          if (_loadingDetails)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (_detailsFailed)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Showing basic info only'),
                  subtitle: const Text('Extra details couldn’t be loaded.'),
                  trailing: TextButton(
                    onPressed: _loadDetails,
                    child: const Text('Retry'),
                  ),
                ),
              ),
            _DetailRow(label: 'Bats', value: _player.batSide),
            _DetailRow(label: 'Throws', value: _player.throwSide),
            _DetailRow(label: 'Height', value: _player.height),
            _DetailRow(
              label: 'Weight',
              value: _player.weight == null ? null : '${_player.weight} lbs',
            ),
            _DetailRow(label: 'Born in', value: _player.birthCountry),
          ],

          const SizedBox(height: 24),
          _buildStatsSection(),

          const SizedBox(height: 20),
          Text('Your note', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Favorite player, great at clutch hits…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_isFavorite)
            Column(
              children: [
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Update note'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _remove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove from favorites'),
                ),
              ],
            )
          else
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.star),
              label: const Text('Save to favorites'),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value ?? '—')),
        ],
      ),
    );
  }
}

/// A single stat box (big value + small label) used in the stats grid.
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: bravesNavy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bravesNavy.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: bravesRed,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
