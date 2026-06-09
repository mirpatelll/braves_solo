import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'services/prefs_service.dart';
import 'screens/home_screen.dart';
import 'screens/roster_screen.dart';
import 'screens/favorites_screen.dart';


const Color bravesRed = Color(0xFFCE1141);
const Color bravesNavy = Color(0xFF13274F);


final ValueNotifier<int> favoritesChanged = ValueNotifier<int>(0);
void notifyFavoritesChanged() => favoritesChanged.value++;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  
  final prefs = PrefsService();
  final darkMode = await prefs.getDarkMode();

  runApp(BravesApp(prefs: prefs, initialDarkMode: darkMode));
}

class BravesApp extends StatefulWidget {
  final PrefsService prefs;
  final bool initialDarkMode;
  const BravesApp({
    super.key,
    required this.prefs,
    required this.initialDarkMode,
  });

  @override
  State<BravesApp> createState() => _BravesAppState();
}

class _BravesAppState extends State<BravesApp> {
  late bool _darkMode = widget.initialDarkMode;

  /// Toggle + persist immediately (per the assignment's prefs guidance).
  Future<void> _toggleDarkMode() async {
    setState(() => _darkMode = !_darkMode);
    await widget.prefs.setDarkMode(_darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Braves Roster & Favorites',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: bravesRed,
          primary: bravesRed,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bravesRed,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: bravesRed,
          primary: bravesRed,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bravesNavy,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeShell(
        prefs: widget.prefs,
        darkMode: _darkMode,
        onToggleDarkMode: _toggleDarkMode,
      ),
    );
  }
}

/// Bottom-nav shell holding the two main screens.
class HomeShell extends StatefulWidget {
  final PrefsService prefs;
  final bool darkMode;
  final VoidCallback onToggleDarkMode;
  const HomeShell({
    super.key,
    required this.prefs,
    required this.darkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToTab: _goToTab,
        darkMode: widget.darkMode,
        onToggleDarkMode: widget.onToggleDarkMode,
      ),
      RosterScreen(
        prefs: widget.prefs,
        darkMode: widget.darkMode,
        onToggleDarkMode: widget.onToggleDarkMode,
      ),
      const FavoritesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_baseball_outlined),
            selectedIcon: Icon(Icons.sports_baseball),
            label: 'Roster',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
