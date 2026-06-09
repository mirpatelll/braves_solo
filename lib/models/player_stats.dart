/// A small, display-ready bundle of a player's season (or career) stats.
///
/// The MLB Stats API returns dozens of raw stat fields; this model picks the
/// handful worth showing and labels them, auto-shaped for hitters vs pitchers.
class PlayerStats {
  /// The season these stats are for, e.g. "2026", or "Career".
  final String season;
  final bool isPitcher;

  /// Ordered (label, value) pairs ready to render as rows.
  final List<MapEntry<String, String>> lines;

  const PlayerStats({
    required this.season,
    required this.isPitcher,
    required this.lines,
  });

  bool get isEmpty => lines.isEmpty;

  /// Builds hitter stats from a `splits[i].stat` map.
  factory PlayerStats.hitting(String season, Map<String, dynamic> stat) {
    return PlayerStats(
      season: season,
      isPitcher: false,
      lines: [
        MapEntry('AVG', _str(stat['avg'])),
        MapEntry('HR', _str(stat['homeRuns'])),
        MapEntry('RBI', _str(stat['rbi'])),
        MapEntry('Hits', _str(stat['hits'])),
        MapEntry('Runs', _str(stat['runs'])),
        MapEntry('OPS', _str(stat['ops'])),
        MapEntry('SB', _str(stat['stolenBases'])),
        MapEntry('Games', _str(stat['gamesPlayed'])),
      ],
    );
  }

  /// Builds pitcher stats from a `splits[i].stat` map.
  factory PlayerStats.pitching(String season, Map<String, dynamic> stat) {
    return PlayerStats(
      season: season,
      isPitcher: true,
      lines: [
        MapEntry('ERA', _str(stat['era'])),
        MapEntry('W–L', '${_str(stat['wins'])}–${_str(stat['losses'])}'),
        MapEntry('SO', _str(stat['strikeOuts'])),
        MapEntry('IP', _str(stat['inningsPitched'])),
        MapEntry('WHIP', _str(stat['whip'])),
        MapEntry('Saves', _str(stat['saves'])),
        MapEntry('Games', _str(stat['gamesPlayed'])),
      ],
    );
  }

  static String _str(dynamic v) => v == null ? '—' : v.toString();
}
