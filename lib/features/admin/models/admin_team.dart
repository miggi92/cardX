class AdminTeam {
  const AdminTeam({
    required this.id,
    required this.clubId,
    required this.sportId,
    required this.seasonId,
    required this.name,
    required this.leagueId,
    required this.ageGroup,
    required this.gender,
    required this.syncEnabled,
    this.externalProvider,
    this.externalTeamId,
    this.lastSyncedAt,
  });

  final String id;
  final String clubId;
  final String sportId;
  final String seasonId;
  final String name;
  final String leagueId;
  final String ageGroup;
  final String gender;
  final String? externalProvider;
  final String? externalTeamId;
  final bool syncEnabled;
  final DateTime? lastSyncedAt;
}

class TeamSyncResult {
  const TeamSyncResult({
    required this.matched,
    required this.created,
    required this.ignored,
    required this.unmatchedNames,
  });

  final int matched;
  final int created;
  final int ignored;
  final List<String> unmatchedNames;
}
