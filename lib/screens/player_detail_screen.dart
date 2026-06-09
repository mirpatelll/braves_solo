import 'package:flutter/material.dart';

import '../main.dart' show notifyFavoritesChanged;
import '../models/player.dart';
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
