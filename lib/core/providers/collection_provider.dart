import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../features/cards/models/card_model.dart';
import '../repositories/supabase_collection_repository.dart';
import 'storage_image_provider.dart';

final collectionRepoProvider = Provider(
  (ref) => SupabaseCollectionRepository(
    imageResolver: ref.watch(storageImageResolverProvider),
  ),
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
      debugPrint('Fehler beim Laden der Karten: $e');
    }
  }

  Future<bool> addCards(List<CardModel> newCards) async {
    final previousState = state;
    state = [...state, ...newCards];
    try {
      await _repository.addCards(newCards);
      return true;
    } catch (e) {
      state = previousState;
      debugPrint('Fehler beim Hinzufuegen der Karten: $e');
      return false;
    }
  }

  Future<bool> removeCard(String cardId) async {
    final index = state.indexWhere((card) => card.id == cardId);

    if (index != -1) {
      final previousState = state;
      final newState = List<CardModel>.from(state);
      newState.removeAt(index);
      state = newState;

      try {
        await _repository.removeCard(cardId);
        return true;
      } catch (e) {
        state = previousState;
        debugPrint('Fehler beim Entfernen der Karte: $e');
        return false;
      }
    }

    return false;
  }

  Future<bool> removeDuplicates() async {
    final Set<String> seenIds = {};
    final List<CardModel> uniqueCards = [];

    for (final card in state) {
      if (!seenIds.contains(card.id)) {
        seenIds.add(card.id);
        uniqueCards.add(card);
      }
    }

    if (state.length != uniqueCards.length) {
      final previousState = state;
      state = uniqueCards;
      try {
        await _repository.syncCollection(state);
        return true;
      } catch (e) {
        state = previousState;
        debugPrint('Fehler beim Synchronisieren der Sammlung: $e');
        return false;
      }
    }

    return true;
  }
}

final collectionProvider =
    NotifierProvider<CollectionNotifier, List<CardModel>>(() {
      return CollectionNotifier();
    });
