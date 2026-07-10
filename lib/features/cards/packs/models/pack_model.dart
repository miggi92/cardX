import 'package:cardx/features/cards/models/card_rarity.dart';

class PackModel {
  final String id;
  final String name;
  final String description;
  final int price;
  final int cardCount;
  final Map<CardRarity, double>
  dropChances; // z.B. {CardRarity.legendary: 0.05}

  const PackModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.cardCount,
    required this.dropChances,
  });

  factory PackModel.fromJson(Map<String, dynamic> json) {
    return PackModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      cardCount: json['cardCount'] as int,
      dropChances: (json['dropChances'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(CardRarity.values.byName(key), (value as num).toDouble()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'cardCount': cardCount,
      'dropChances': dropChances.map((key, value) => MapEntry(key.name, value)),
    };
  }
}
