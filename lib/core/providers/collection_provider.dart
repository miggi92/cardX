import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cards/models/card_model.dart';

class CollectionNotifier extends Notifier<List<CardModel>> {
  @override
  List<CardModel> build() {
    return []; // Die Sammlung startet leer
  }

  void addCards(List<CardModel> newCards) {
    // Nimmt die alten Karten (...state) und packt die neuen dazu
    state = [...state, ...newCards];
  }
}

final collectionProvider =
    NotifierProvider<CollectionNotifier, List<CardModel>>(() {
      return CollectionNotifier();
    });
