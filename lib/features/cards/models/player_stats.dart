class PlayerStats {
  final int goals;
  final int games;
  final List<PlayerTeamStats> teams;

  const PlayerStats({
    required this.goals,
    required this.games,
    this.teams = const [],
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      games: (json['games'] as num?)?.toInt() ?? 0,
      teams: (json['teams'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PlayerTeamStats.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goals': goals,
      'games': games,
      'teams': teams.map((team) => team.toJson()).toList(),
    };
  }

  factory PlayerStats.fromSupabase({dynamic legacyStats, dynamic memberships}) {
    final legacy = _readLegacyStats(legacyStats);
    final teams = memberships is List
        ? memberships
              .whereType<Map>()
              .map(PlayerTeamStats.fromSupabase)
              .whereType<PlayerTeamStats>()
              .toList()
        : <PlayerTeamStats>[];

    teams.sort((a, b) {
      final aTime = a.lastSyncedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.lastSyncedAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    final latest = teams.firstOrNull;
    return PlayerStats(
      goals: latest?.integerValue('goals') ?? legacy.$1,
      games:
          latest?.integerValue('gamesPlayed') ??
          latest?.integerValue('games') ??
          legacy.$2,
      teams: teams,
    );
  }

  static (int, int) _readLegacyStats(dynamic rawStats) {
    if (rawStats is Map) {
      return (
        (rawStats['goals'] as num?)?.toInt() ?? 0,
        (rawStats['games'] as num?)?.toInt() ?? 0,
      );
    }
    if (rawStats is List && rawStats.isNotEmpty && rawStats.first is Map) {
      return _readLegacyStats(rawStats.first);
    }
    return (0, 0);
  }
}

class PlayerTeamStats {
  const PlayerTeamStats({
    required this.teamName,
    required this.season,
    required this.ageGroup,
    required this.gender,
    required this.sport,
    required this.league,
    required this.values,
    this.lastSyncedAt,
  });

  final String teamName;
  final String season;
  final String ageGroup;
  final String gender;
  final String sport;
  final String league;
  final Map<String, num> values;
  final DateTime? lastSyncedAt;

  int? integerValue(String key) => values[key]?.toInt();

  factory PlayerTeamStats.fromJson(Map<String, dynamic> json) {
    return PlayerTeamStats(
      teamName: json['teamName'] as String? ?? '',
      season: json['season'] as String? ?? '',
      ageGroup: json['ageGroup'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      sport: json['sport'] as String? ?? '',
      league: json['league'] as String? ?? '',
      values: _readValues(json['values']),
      lastSyncedAt: DateTime.tryParse(json['lastSyncedAt'] as String? ?? ''),
    );
  }

  static PlayerTeamStats? fromSupabase(Map membership) {
    if (membership['is_active'] == false) {
      return null;
    }

    final rawTeam = membership['club_season_teams'];
    if (rawTeam is! Map) {
      return null;
    }

    final rawStats = membership['player_team_stats'];
    final stats = rawStats is List
        ? rawStats.whereType<Map>().firstOrNull
        : rawStats is Map
        ? rawStats
        : null;
    if (stats == null) {
      return null;
    }

    return PlayerTeamStats(
      teamName: rawTeam['team_name'] as String? ?? '',
      season: rawTeam['season_id'] as String? ?? '',
      ageGroup: rawTeam['age_group'] as String? ?? '',
      gender: rawTeam['gender'] as String? ?? '',
      sport: rawTeam['sport_id'] as String? ?? '',
      league: rawTeam['league_id'] as String? ?? '',
      values: _readValues(stats['stats']),
      lastSyncedAt: DateTime.tryParse(stats['last_synced_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamName': teamName,
      'season': season,
      'ageGroup': ageGroup,
      'gender': gender,
      'sport': sport,
      'league': league,
      'values': values,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  static Map<String, num> _readValues(dynamic rawValues) {
    if (rawValues is! Map) {
      return const {};
    }
    return {
      for (final entry in rawValues.entries)
        if (entry.key is String && entry.value is num)
          entry.key as String: entry.value as num,
    };
  }
}
