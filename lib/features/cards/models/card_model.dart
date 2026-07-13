import 'card_rarity.dart';
import 'player_stats.dart';

class CardModel {
  final String id;
  final String playerName;
  final String position;
  final String teamName;
  final String teamLogoUrl;
  final String playerImageUrl;
  final CardRarity rarity;
  final PlayerStats stats;
  final String sport;

  const CardModel({
    required this.id,
    required this.playerName,
    required this.position,
    required this.teamName,
    required this.teamLogoUrl,
    required this.playerImageUrl,
    required this.rarity,
    required this.stats,
    this.sport = '',
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      playerName: json['playerName'] as String,
      position: json['position'] as String,
      teamName: json['teamName'] as String,
      teamLogoUrl: json['teamLogoUrl'] as String,
      playerImageUrl: json['playerImageUrl'] as String,
      rarity: CardRarity.values.byName(json['rarity'] as String),
      stats: PlayerStats.fromJson(json['stats'] as Map<String, dynamic>),
      sport: (json['sport'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerName': playerName,
      'position': position,
      'teamName': teamName,
      'teamLogoUrl': teamLogoUrl,
      'playerImageUrl': playerImageUrl,
      'rarity': rarity.name,
      'stats': stats.toJson(),
      'sport': sport,
    };
  }
}
