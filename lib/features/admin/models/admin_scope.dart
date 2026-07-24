class AdminClubPermission {
  const AdminClubPermission({
    required this.clubId,
    required this.clubName,
    required this.canCreatePlayers,
    required this.canEditPlayers,
  });

  final String clubId;
  final String clubName;
  final bool canCreatePlayers;
  final bool canEditPlayers;
}

class AdminScope {
  const AdminScope({required this.isGlobalAdmin, required this.clubs});

  final bool isGlobalAdmin;
  final List<AdminClubPermission> clubs;

  bool get canManagePlayers =>
      isGlobalAdmin ||
      clubs.any((club) => club.canCreatePlayers || club.canEditPlayers);

  AdminClubPermission? permissionForClub(String clubId) {
    for (final club in clubs) {
      if (club.clubId == clubId) {
        return club;
      }
    }
    return null;
  }
}

class AdminPlayer {
  const AdminPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.clubId,
    required this.clubName,
    required this.sport,
    required this.league,
    required this.season,
    required this.goals,
    required this.games,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String position;
  final String clubId;
  final String clubName;
  final String sport;
  final String league;
  final String season;
  final int goals;
  final int games;
  final String imageUrl;
}
