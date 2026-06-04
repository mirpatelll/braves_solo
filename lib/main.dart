import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFCE1141),
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
              const Text(
                'Welcome to the Braves App!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Image.asset(
                'assets/Atlanta-Braves-logo.png',
                height: 150,
              ),
              const SizedBox(height: 24),
              const Text(
                'Your home for all things Braves.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
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

class BravesInfoScreen extends StatelessWidget {
  const BravesInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFCE1141),
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
              Image.asset(
                'assets/Atlanta-Braves-logo.png',
                height: 150,
              ),
              const SizedBox(height: 24),
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
                      builder: (context) => const PlayerCompareScreen(),
                    ),
                  );
                },
                child: const Text('Compare Players'),
              ),
              const SizedBox(height: 12),
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
                  Navigator.pop(context);
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

const List<Color> bgColors = [
  Color(0xFFCE1141),
  Color(0xFF13274F),
  Color(0xFFFFC72C),
  Color(0xFFFFFFFF),
  Color(0xFF1A1A1A),
];

Color getForegroundColor(Color bg) {
  if (bg.computeLuminance() > 0.4) {
    return Colors.black;
  } else {
    return Colors.white;
  }
}

class PlayerCompareScreen extends StatefulWidget {
  const PlayerCompareScreen({super.key});

  @override
  State<PlayerCompareScreen> createState() => _PlayerCompareScreenState();
}

class _PlayerCompareScreenState extends State<PlayerCompareScreen> {
  int colorIndex = 0;
  final player1Controller = TextEditingController();
  final player2Controller = TextEditingController();
  String? player1Error;
  String? player2Error;
  String result = '';

  void cycleColor() {
    setState(() {
      colorIndex = (colorIndex + 1) % bgColors.length;
    });
  }

  void compare() {
    setState(() {
      player1Error = null;
      player2Error = null;
      result = '';

      String text1 = player1Controller.text.trim();
      String text2 = player2Controller.text.trim();

      if (text1.isEmpty) {
        player1Error = 'Please enter a batting average.';
      } else if (double.tryParse(text1) == null) {
        player1Error = 'Must be a number like 0.300';
      } else if (double.parse(text1) < 0 || double.parse(text1) > 1) {
        player1Error = 'Must be between 0.000 and 1.000';
      }

      if (text2.isEmpty) {
        player2Error = 'Please enter a batting average.';
      } else if (double.tryParse(text2) == null) {
        player2Error = 'Must be a number like 0.300';
      } else if (double.parse(text2) < 0 || double.parse(text2) > 1) {
        player2Error = 'Must be between 0.000 and 1.000';
      }

      if (player1Error == null && player2Error == null) {
        double avg1 = double.parse(text1);
        double avg2 = double.parse(text2);
        double diff = (avg1 - avg2).abs();

        if (avg1 > avg2) {
          result = 'Player 1 has the higher average by ${diff.toStringAsFixed(3)} points.';
        } else if (avg2 > avg1) {
          result = 'Player 2 has the higher average by ${diff.toStringAsFixed(3)} points.';
        } else {
          result = 'Both players have the same batting average!';
        }
      }
    });
  }

  @override
  void dispose() {
    player1Controller.dispose();
    player2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bg = bgColors[colorIndex];
    Color fg = getForegroundColor(bg);

    return GestureDetector(
      onTap: cycleColor,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          foregroundColor: fg,
          title: Text(
            'Player Comparison',
            style: TextStyle(color: fg),
          ),
          iconTheme: IconThemeData(color: fg),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Compare Batting Averages',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap empty areas to change background color.',
                  style: TextStyle(fontSize: 13, color: fg.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'Player 1 Batting Average',
                  style: TextStyle(fontSize: 16, color: fg),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: player1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'e.g. 0.325',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: player1Error,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Player 2 Batting Average',
                  style: TextStyle(fontSize: 16, color: fg),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: player2Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'e.g. 0.280',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: player2Error,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCE1141),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: compare,
                  child: const Text(
                    'Compare',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
                if (result.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: fg.withOpacity(0.4)),
                    ),
                    child: Text(
                      result,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: fg,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCE1141),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Back to Team Info'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}