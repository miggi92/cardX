class AdminUserOption {
  const AdminUserOption({required this.userId, required this.email});

  final String userId;
  final String email;
}

class ClubAdminRoleAssignment {
  const ClubAdminRoleAssignment({
    required this.userId,
    required this.email,
    required this.clubId,
    required this.clubName,
    required this.canCreatePlayers,
    required this.canEditPlayers,
  });

  final String userId;
  final String? email;
  final String clubId;
  final String clubName;
  final bool canCreatePlayers;
  final bool canEditPlayers;
}
