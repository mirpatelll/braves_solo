import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Root widget that sets up the app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Braves App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

// Screen 1: Home Screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top app bar
      appBar: AppBar(
        backgroundColor: const Color(0xFFCE1141), // Braves red
        title: const Text(
          'Atlanta Braves',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title text
              const Text(
                'Welcome to the Braves App!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Local asset image (Screen 1)
              Image.asset(
                'assets/Atlanta-Braves-logo.png',
                height: 150,
              ),
              const SizedBox(height: 24),

              // Description text
              const Text(
                'Your home for all things Braves.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Button to navigate to Screen 2
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCE1141),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BravesInfoScreen(),
                    ),
                  );
                },
                child: const Text('View Team Info'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Screen 2: Braves Info Screen
class BravesInfoScreen extends StatelessWidget {
  const BravesInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top app bar
      appBar: AppBar(
        backgroundColor: const Color(0xFFCE1141), // Braves red
        title: const Text(
          'Team Info',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Local asset image (Screen 2)
              Image.asset(
                'assets/Atlanta-Braves-logo.png',
                height: 150,
              ),
              const SizedBox(height: 24),

              // Team info text
              const Text(
                'Atlanta Braves',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'League: National League East',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Home: Truist Park, Cumberland GA',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'World Series Titles: 4',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Most Recent Title: 2021',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Back button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCE1141),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // Go back to Home
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}