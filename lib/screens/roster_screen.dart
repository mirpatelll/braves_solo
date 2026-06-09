import 'package:flutter/material.dart';

import '../main.dart' show favoritesChanged, notifyFavoritesChanged;
import '../models/player.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/prefs_service.dart';
import 'player_detail_screen.dart';

/// One of four mutually-exclusive view states for the fetch.
enum _ViewState { loading, error, empty, success }

/// Part A — fetches and displays the live Braves roster, with search, a
/// pull-to-refresh, and explicit loading / error / empty / success states.
class RosterScreen extends StatefulWidget {
  final PrefsService prefs;
  final bool darkMode;
  final VoidCallback onToggleDarkMode;
  const RosterScreen({
    super.key,
    required this.prefs,
    required this.darkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final _api = ApiService();
  final _db = DatabaseHelper.instance;
  final _searchController = TextEditingController();

  _ViewState _state = _ViewState.loading;
  String _errorMessage = '';
  List<Player> _allPlayers = [];
  List<Player> _filtered = [];
  Set<int> _favoriteIds = {};
  SortOrder _sortOrder = SortOrder.nameAsc;

  @override
  void initState() {
    super.initState();
    // Re-mark saved players whenever favorites change elsewhere in the app.
    favoritesChanged.addListener(_reloadFavoriteIds);
    _bootstrap();
  }

  @override
  void dispose() {
    favoritesChanged.removeListener(_reloadFavoriteIds);
    _searchController.dispose();
    _api.dispose();
    super.dispose();
  }

  /// Restores persisted prefs (sort order + last query) then fetches.
  Future<void> _bootstrap() async {
    _sortOrder = await widget.prefs.getSortOrder();
    _searchController.text = await widget.prefs.getLastQuery();
    await _loadRoster();
  }

  Future<void> _reloadFavoriteIds() async {
    final ids = await _db.getFavoriteIds();
    if (mounted) {
      setState(() {
        _favoriteIds = ids;
        _applyFilter(); // keep marks in sync if list is showing
      });
    }
  }

  Future<void> _loadRoster() async {
    setState(() {
      _state = _ViewState.loading;
      _errorMessage = '';
    });
    try {
      final players = await _api.fetchRoster();
      _favoriteIds = await _db.getFavoriteIds();
      if (!mounted) return;
      setState(() {
        _allPlayers = players;
        _applyFilter();
        _state = _allPlayers.isEmpty ? _ViewState.empty : _ViewState.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ViewState.error;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _ViewState.error;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    var list = q.isEmpty
        ? List<Player>.from(_allPlayers)
        : _allPlayers
            .where((p) =>
                p.fullName.toLowerCase().contains(q) ||
                p.position.toLowerCase().contains(q) ||
                p.jerseyNumber.contains(q))
            .toList();

    switch (_sortOrder) {
      case SortOrder.nameAsc:
        list.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case SortOrder.nameDesc:
        list.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case SortOrder.jersey:
        list.sort((a, b) =>
            (int.tryParse(a.jerseyNumber) ?? 999)
                .compareTo(int.tryParse(b.jerseyNumber) ?? 999));
        break;
    }
    _filtered = list;
  }

  void _onSearchChanged(String value) {
    setState(_applyFilter);
    widget.prefs.setLastQuery(value); // persist immediately
  }

  Future<void> _changeSort(SortOrder order) async {
    setState(() {
      _sortOrder = order;
      _applyFilter();
    });
    await widget.prefs.setSortOrder(order); // persist immediately
  }

  Future<void> _toggleFavorite(Player player) async {
    final wasFav = _favoriteIds.contains(player.id);
    if (wasFav) {
      await _db.deletePlayer(player.id);
    } else {
      await _db.savePlayer(
        player.copyWith(savedAt: DateTime.now().millisecondsSinceEpoch),
      );
    }
    await _reloadFavoriteIds();
    notifyFavoritesChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wasFav
                ? 'Removed ${player.fullName} from favorites'
                : 'Saved ${player.fullName} to favorites',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Braves Active Roster'),
        actions: [
          PopupMenuButton<SortOrder>(
            tooltip: 'Sort order',
            icon: const Icon(Icons.sort),
            onSelected: _changeSort,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: SortOrder.nameAsc,
                child: Text('Name (A–Z)'),
              ),
              PopupMenuItem(
                value: SortOrder.nameDesc,
                child: Text('Name (Z–A)'),
              ),
              PopupMenuItem(
                value: SortOrder.jersey,
                child: Text('Jersey number'),
              ),
            ],
          ),
          IconButton(
            tooltip: widget.darkMode ? 'Switch to light' : 'Switch to dark',
            icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleDarkMode,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name, position, or number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ViewState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading roster…'),
            ],
          ),
        );

      case _ViewState.error:
        return _ErrorState(message: _errorMessage, onRetry: _loadRoster);

      case _ViewState.empty:
        return const _MessageState(
          icon: Icons.inbox_outlined,
          title: 'No players found',
          subtitle: 'The roster came back empty. Pull down to refresh.',
        );

      case _ViewState.success:
        if (_filtered.isEmpty) {
          // Empty *search result* — distinct from an empty roster.
          return const _MessageState(
            icon: Icons.search_off,
            title: 'No matches',
            subtitle: 'No players match your search. Try a different term.',
          );
        }
        return RefreshIndicator(
          onRefresh: _loadRoster,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _filtered.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = _filtered[i];
              final isFav = _favoriteIds.contains(p.id);
              return ListTile(
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundImage: NetworkImage(p.headshotUrl),
                  child: const Icon(Icons.person),
                ),
                title: Text(
                  p.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('#${p.jerseyNumber} · ${p.position}'),
                trailing: IconButton(
                  tooltip: isFav ? 'Remove favorite' : 'Add favorite',
                  icon: Icon(
                    isFav ? Icons.star : Icons.star_border,
                    color: isFav ? Colors.amber : null,
                  ),
                  onPressed: () => _toggleFavorite(p),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PlayerDetailScreen(player: p, api: _api),
                    ),
                  );
                  _reloadFavoriteIds(); // may have changed on detail screen
                },
              );
            },
          ),
        );
    }
  }
}

/// Friendly error UI with a working Retry button.
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Couldn’t load the roster',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic centered icon + title + subtitle used for empty states.
class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
