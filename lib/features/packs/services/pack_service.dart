import 'dart:math';
import '../../cards/models/card_model.dart';
import '../../cards/models/card_rarity.dart';
import '../models/pack_model.dart';

class PackService {
  final Random _random = Random();

  List<CardModel> openPack(PackModel pack, List<CardModel> cardPool) {
    List<CardModel> drawnCards = [];

    for (int i = 0; i < pack.cardCount; i++) {
      CardRarity drawnRarity = _determineRarity(pack.dropChances);

      List<CardModel> availableCardsOfRarity = cardPool
          .where((card) => card.rarity == drawnRarity)
          .toList();

      if (availableCardsOfRarity.isNotEmpty) {
        int randomIndex = _random.nextInt(availableCardsOfRarity.length);
        drawnCards.add(availableCardsOfRarity[randomIndex]);
      }
    }

    return drawnCards;
  }

  CardRarity _determineRarity(Map<CardRarity, double> dropChances) {
    double roll = _random.nextDouble();
    double cumulativeProbability = 0.0;

    for (var entry in dropChances.entries) {
      cumulativeProbability += entry.value;
      if (roll <= cumulativeProbability) {
        return entry.key;
      }
    }

    return CardRarity.common;
  }
}
