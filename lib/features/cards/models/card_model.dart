import 'card_rarity.dart';
import 'player_stats.dart';

class CardModel {
  final String id;
  final String playerName;
  final String position;
  final String teamName;
  final String? imageUrl;
  final CardRarity rarity;
  final PlayerStats stats;
  final int overallRating;

  const CardModel({
    required this.id,
    required this.playerName,
    required this.position,
    required this.teamName,
    this.imageUrl,
    required this.rarity,
    required this.stats,
    required this.overallRating,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      playerName: json['playerName'] as String,
      position: json['position'] as String,
      teamName: json['teamName'] as String,
      imageUrl: json['imageUrl'] as String?,
      rarity: CardRarity.values.byName(json['rarity'] as String),
      stats: PlayerStats.fromJson(json['stats'] as Map<String, dynamic>),
      overallRating: json['overallRating'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerName': playerName,
      'position': position,
      'teamName': teamName,
      'imageUrl': imageUrl,
      'rarity': rarity.name,
      'stats': stats.toJson(),
      'overallRating': overallRating,
    };
  }
}
