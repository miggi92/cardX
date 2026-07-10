import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cards/models/card_model.dart';
import '../repositories/supabase_collection_repository.dart';

final collectionRepoProvider = Provider(
  (ref) => SupabaseCollectionRepository(),
);

class CollectionNotifier extends Notifier<List<CardModel>> {
  late final _repository = ref.watch(collectionRepoProvider);

  @override
  List<CardModel> build() {
    _loadInitialCards();
    return [];
  }

  Future<void> _loadInitialCards() async {
    try {
      state = await _repository.getCards();
    } catch (e) {
      print("Fehler beim Laden der Karten: $e");
    }
  }

  void addCards(List<CardModel> newCards) {
    state = [...state, ...newCards];
    _repository.addCards(newCards);
  }

  void removeCard(String cardId) {
    final index = state.indexWhere((card) => card.id == cardId);

    if (index != -1) {
      final newState = List<CardModel>.from(state);
      newState.removeAt(index);
      state = newState;

      _repository.removeCard(cardId);
    }
  }

  void removeDuplicates() {
    final Set<String> seenIds = {};
    final List<CardModel> uniqueCards = [];

    for (final card in state) {
      if (!seenIds.contains(card.id)) {
        seenIds.add(card.id);
        uniqueCards.add(card);
      }
    }

    if (state.length != uniqueCards.length) {
      state = uniqueCards;
      _repository.syncCollection(state);
    }
  }
}

final collectionProvider =
    NotifierProvider<CollectionNotifier, List<CardModel>>(() {
      return CollectionNotifier();
    });
