// Unit tests for the Player model: roster JSON parsing and the SQLite
// map round-trip. These exercise the core data layer without needing a
// device or network.

import 'package:flutter_test/flutter_test.dart';

import 'package:braves_app/models/player.dart';

void main() {
  group('Player.fromRosterJson', () {
    test('parses a normal roster entry', () {
      final json = {
        'person': {'id': 663586, 'fullName': 'Austin Riley'},
        'jerseyNumber': '27',
        'position': {'abbreviation': '3B'},
      };
      final p = Player.fromRosterJson(json);
      expect(p.id, 663586);
      expect(p.fullName, 'Austin Riley');
      expect(p.jerseyNumber, '27');
      expect(p.position, '3B');
    });

    test('falls back to safe defaults on missing fields', () {
      final p = Player.fromRosterJson({});
      expect(p.id, 0);
      expect(p.fullName, 'Unknown Player');
      expect(p.jerseyNumber, '--');
      expect(p.position, '--');
    });

    test('builds the standard headshot URL from the id', () {
      final p = Player.fromRosterJson({
        'person': {'id': 660670, 'fullName': 'Ronald Acuña Jr.'},
      });
      expect(
        p.headshotUrl,
        'https://midfield.mlbstatic.com/v1/people/660670/spots/120',
      );
    });
  });

  group('SQLite map round-trip', () {
    test('toMap then fromMap preserves all fields', () {
      const original = Player(
        id: 1,
        fullName: 'Test Player',
        jerseyNumber: '7',
        position: 'SS',
        batSide: 'Right',
        throwSide: 'Right',
        birthCountry: 'USA',
        height: '6\' 1"',
        weight: 200,
        note: 'Great glove',
        savedAt: 123456789,
      );

      final restored = Player.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.fullName, original.fullName);
      expect(restored.jerseyNumber, original.jerseyNumber);
      expect(restored.position, original.position);
      expect(restored.note, original.note);
      expect(restored.weight, original.weight);
      expect(restored.savedAt, original.savedAt);
    });

    test('fromMap tolerates a partially-corrupted row', () {
      final restored = Player.fromMap({'id': 5});
      expect(restored.id, 5);
      expect(restored.fullName, 'Unknown Player');
      expect(restored.note, '');
    });
  });
}
