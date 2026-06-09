import 'package:flutter/material.dart';

import '../main.dart' show favoritesChanged, bravesRed, bravesNavy;
import '../services/database_helper.dart';

/// Animated landing/dashboard screen — the app's "front door".
///
/// Shows the Braves logo (with a gentle continuous pulse), a staggered
/// entrance animation, a live favorites count pulled from SQLite, and
/// quick-action cards that jump to the Roster / Favorites tabs.
class HomeScreen extends StatefulWidget {
  /// Switches the bottom-nav tab (1 = Roster, 2 = Favorites).
  final ValueChanged<int> onNavigateToTab;
  final bool darkMode;
  final VoidCallback onToggleDarkMode;

  const HomeScreen({
    super.key,
    required this.onNavigateToTab,
    required this.darkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // Drives the one-shot staggered entrance (logo -> title -> cards).
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  // Drives the subtle, looping logo "breathing" pulse.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  int _favoriteCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
    favoritesChanged.addListener(_loadCount);
  }

  @override
  void dispose() {
    favoritesChanged.removeListener(_loadCount);
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadCount() async {
    try {
      final ids = await DatabaseHelper.instance.getFavoriteIds();
      if (mounted) setState(() => _favoriteCount = ids.length);
    } catch (_) {
      // First run / no DB yet — just leave the count at 0.
    }
  }

  /// Builds a fade + slide-up transition for an entrance segment.
  Widget _staggered({
    required double start,
    required double end,
    required Widget child,
  }) {
    final curved = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, c) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - curved.value)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bravesNavy, Color(0xFF0A1530)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Theme toggle, top-right.
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: widget.darkMode
                        ? 'Switch to light'
                        : 'Switch to dark',
                    onPressed: widget.onToggleDarkMode,
                    icon: Icon(
                      widget.darkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Pulsing logo.
                _staggered(
                  start: 0.0,
                  end: 0.45,
                  child: Center(
                    child: ScaleTransition(
                      scale: Tween(begin: 0.96, end: 1.04).animate(
                        CurvedAnimation(
                          parent: _pulse,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 170,
                        height: 170,
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: bravesRed.withValues(alpha: 0.45),
                              blurRadius: 45,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/braves_a_logo.png',
                          fit: BoxFit.contain,
                          // Graceful fallback if the asset is missing.
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.sports_baseball,
                            size: 110,
                            color: bravesRed,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title + tagline.
                _staggered(
                  start: 0.25,
                  end: 0.6,
                  child: Column(
                    children: [
                      const Text(
                        'Atlanta Braves',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Roster & Favorites',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Browse · Favorite · Remember',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: bravesRed.withValues(alpha: 0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Live favorites count (animated number).
                _staggered(
                  start: 0.45,
                  end: 0.8,
                  child: _StatBanner(count: _favoriteCount),
                ),
                const SizedBox(height: 24),

                // Quick-action cards.
                _staggered(
                  start: 0.6,
                  end: 0.95,
                  child: _ActionCard(
                    icon: Icons.sports_baseball,
                    title: 'Browse Roster',
                    subtitle: 'See the live active roster from the MLB API',
                    color: bravesRed,
                    onTap: () => widget.onNavigateToTab(1),
                  ),
                ),
                const SizedBox(height: 14),
                _staggered(
                  start: 0.7,
                  end: 1.0,
                  child: _ActionCard(
                    icon: Icons.star,
                    title: 'My Favorites',
                    subtitle: _favoriteCount == 0
                        ? 'No saved players yet — tap to start'
                        : 'View your $_favoriteCount saved '
                            '${_favoriteCount == 1 ? "player" : "players"}',
                    color: const Color(0xFFFFC72C),
                    iconColor: Colors.black87,
                    onTap: () => widget.onNavigateToTab(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass-style banner showing the saved-favorites count, with the number
/// animating up whenever it changes.
class _StatBanner extends StatelessWidget {
  final int count;
  const _StatBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark, color: Color(0xFFFFC72C), size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: count),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, _) => Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'players saved locally',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tappable action card with an icon, title and subtitle.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 34),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: iconColor.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: iconColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
