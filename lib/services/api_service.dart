import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/player.dart';

/// Thrown for any user-recoverable network/parse problem so the UI can show a
/// friendly message + Retry instead of a raw exception.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Talks to the free, no-auth MLB Stats API.
///
/// Example endpoint:
///   https://statsapi.mlb.com/api/v1/teams/144/roster?rosterType=active
/// (144 is the Atlanta Braves team id.)
class ApiService {
  static const String _base = 'https://statsapi.mlb.com/api/v1';
  static const int bravesTeamId = 144;

  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// HTTP GET the active Braves roster and parse it into typed [Player]s.
  Future<List<Player>> fetchRoster() async {
    final uri = Uri.parse('$_base/teams/$bravesTeamId/roster?rosterType=active');
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw ApiException(
          'Server returned ${res.statusCode}. Please try again.',
        );
      }

      final decoded = json.decode(res.body) as Map<String, dynamic>;
      final roster = decoded['roster'] as List<dynamic>? ?? const [];

      final players = roster
          .whereType<Map<String, dynamic>>()
          .map(Player.fromRosterJson)
          .where((p) => p.id != 0)
          .toList();

      // Sort alphabetically for a stable, predictable list.
      players.sort((a, b) => a.fullName.compareTo(b.fullName));
      return players;
    } on TimeoutException {
      throw ApiException('Request timed out. Check your connection and retry.');
    } on FormatException {
      throw ApiException('Received malformed data from the server.');
    } on http.ClientException {
      throw ApiException('Network error. Are you online?');
    }
  }

  /// Fetches richer details (bats/throws, height, country, …) for one player.
  /// Failures here are non-fatal — callers fall back to the roster-level data.
  Future<Player> fetchPlayerDetails(Player base) async {
    final uri = Uri.parse('$_base/people/${base.id}');
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw ApiException('Could not load details (${res.statusCode}).');
    }
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    final people = decoded['people'] as List<dynamic>? ?? const [];
    if (people.isEmpty) return base;
    return base.withDetails(people.first as Map<String, dynamic>);
  }

  void dispose() => _client.close();
}
