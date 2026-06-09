import 'package:flutter/material.dart';

import '../main.dart' show favoritesChanged, notifyFavoritesChanged;
import '../models/player.dart';
import '../services/database_helper.dart';

/// Part B — shows all locally-saved (SQLite) favorite players. Works fully
/// offline: this screen never touches the network. Supports per-item delete,
/// Clear All, editing notes, and a welcoming first-run/empty state.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _db = DatabaseHelper.instance;

  bool _loading = true;
  List<Player> _favorites = [];

  @override
  void initState() {
    super.initState();
    // Load persisted favorites on start.
    _load();
    // Reload whenever favorites change anywhere in the app.
    favoritesChanged.addListener(_load);
  }

  @override
  void dispose() {
    favoritesChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final favs = await _db.getFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favs;
        _loading = false;
      });
    } catch (_) {
      // Even a corrupt/missing DB should not crash the screen.
      if (!mounted) return;
      setState(() {
        _favorites = [];
        _loading = false;
      });
    }
  }

  Future<void> _delete(Player player) async {
    await _db.deletePlayer(player.id);
    notifyFavoritesChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Deleted ${player.fullName}')),
      );
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all favorites?'),
        content: const Text(
          'This removes every saved player from local storage. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.clearAll();
    notifyFavoritesChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Cleared all favorites')));
  }

  Future<void> _editNote(Player player) async {
    final controller = TextEditingController(text: player.note);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Note · ${player.fullName}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Add a personal note…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await _db.updateNote(player.id, controller.text.trim());
      notifyFavoritesChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favorites (${_favorites.length})'),
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_border, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'No favorites yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Head to the Roster tab and tap the ☆ on any player '
                'to save them here. Your favorites stay on this device '
                'and work offline.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _favorites.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = _favorites[i];
        return Dismissible(
          key: ValueKey(p.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _delete(p),
          child: ListTile(
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${p.jerseyNumber} · ${p.position}'),
                if (p.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '“${p.note}”',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
            isThreeLine: p.note.isNotEmpty,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit note',
                  icon: const Icon(Icons.edit_note),
                  onPressed: () => _editNote(p),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(p),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
