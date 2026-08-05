class SocialProfile {
  const SocialProfile({required this.username, required this.inviteToken});

  final String? username;
  final String inviteToken;

  String get inviteLink => 'cardx://friend/$inviteToken';
}

class FriendProfile {
  const FriendProfile({
    required this.userId,
    required this.username,
    required this.friendsSince,
  });

  final String userId;
  final String? username;
  final DateTime friendsSince;
}