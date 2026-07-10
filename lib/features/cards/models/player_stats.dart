class PlayerStats {
  final int goals;
  final int games;

  const PlayerStats({required this.goals, required this.games});

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      goals: json['goals'] as int,
      games: json['games'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'goals': goals, 'games': games};
  }
}
