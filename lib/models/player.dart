/// A single Atlanta Braves player.
///
/// The same class is used for three things:
///   1. Decoding the MLB Stats API roster JSON  -> [Player.fromRosterJson]
///   2. Decoding extra detail from the people endpoint -> [Player.withDetails]
///   3. Reading/writing rows in the local SQLite database -> [toMap] / [fromMap]
class Player {
  final int id;
  final String fullName;
  final String jerseyNumber;
  final String position;

  // Extra fields that may be filled in from the player-detail endpoint or DB.
  final String? batSide;
  final String? throwSide;
  final String? birthCountry;
  final String? height;
  final int? weight;

  // Only used for saved/favorite rows.
  final String note;
  final int? savedAt; // millisecondsSinceEpoch

  const Player({
    required this.id,
    required this.fullName,
    required this.jerseyNumber,
    required this.position,
    this.batSide,
    this.throwSide,
    this.birthCountry,
    this.height,
    this.weight,
    this.note = '',
    this.savedAt,
  });

  /// Standard MLB headshot URL — works for any valid player id, no auth needed.
  String get headshotUrl =>
      'https://midfield.mlbstatic.com/v1/people/$id/spots/120';

  /// Builds a Player from one entry of the `roster` array.
  factory Player.fromRosterJson(Map<String, dynamic> json) {
    final person = json['person'] as Map<String, dynamic>? ?? const {};
    final position = json['position'] as Map<String, dynamic>? ?? const {};
    return Player(
      id: person['id'] as int? ?? 0,
      fullName: person['fullName'] as String? ?? 'Unknown Player',
      jerseyNumber: (json['jerseyNumber'] as String?) ?? '--',
      position: (position['abbreviation'] as String?) ?? '--',
    );
  }

  /// Returns a copy of this player enriched with fields from the
  /// `/people/{id}` detail endpoint.
  Player withDetails(Map<String, dynamic> personJson) {
    final pos = personJson['primaryPosition'] as Map<String, dynamic>?;
    final bat = personJson['batSide'] as Map<String, dynamic>?;
    final throwS = personJson['pitchHand'] as Map<String, dynamic>?;
    return copyWith(
      position: (pos?['abbreviation'] as String?) ?? position,
      jerseyNumber:
          (personJson['primaryNumber'] as String?) ?? jerseyNumber,
      batSide: bat?['description'] as String?,
      throwSide: throwS?['description'] as String?,
      birthCountry: personJson['birthCountry'] as String?,
      height: personJson['height'] as String?,
      weight: personJson['weight'] as int?,
    );
  }

  Player copyWith({
    String? fullName,
    String? jerseyNumber,
    String? position,
    String? batSide,
    String? throwSide,
    String? birthCountry,
    String? height,
    int? weight,
    String? note,
    int? savedAt,
  }) {
    return Player(
      id: id,
      fullName: fullName ?? this.fullName,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      position: position ?? this.position,
      batSide: batSide ?? this.batSide,
      throwSide: throwSide ?? this.throwSide,
      birthCountry: birthCountry ?? this.birthCountry,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      note: note ?? this.note,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  /// Maps to a SQLite row. Column names match the table in DatabaseHelper.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'jerseyNumber': jerseyNumber,
      'position': position,
      'batSide': batSide,
      'throwSide': throwSide,
      'birthCountry': birthCountry,
      'height': height,
      'weight': weight,
      'note': note,
      'savedAt': savedAt ?? 0,
    };
  }

  /// Rebuilds a Player from a SQLite row. Tolerant of missing/null columns
  /// so a partially-corrupted or older-schema row never crashes the app.
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as int? ?? 0,
      fullName: map['fullName'] as String? ?? 'Unknown Player',
      jerseyNumber: map['jerseyNumber'] as String? ?? '--',
      position: map['position'] as String? ?? '--',
      batSide: map['batSide'] as String?,
      throwSide: map['throwSide'] as String?,
      birthCountry: map['birthCountry'] as String?,
      height: map['height'] as String?,
      weight: map['weight'] as int?,
      note: map['note'] as String? ?? '',
      savedAt: map['savedAt'] as int?,
    );
  }
}
