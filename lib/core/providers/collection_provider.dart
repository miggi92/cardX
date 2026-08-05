import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/cards/models/card_model.dart';
import '../repositories/local_collection_repository.dart';
import '../repositories/supabase_collection_repository.dart';
import 'storage_image_provider.dart';

final collectionRepoProvider = Provider(
  (ref) => SupabaseCollectionRepository(
    imageResolver: ref.watch(storageImageResolverProvider),
  ),
);

class CollectionNotifier extends Notifier<List<CardModel>> {
  late final _repository = ref.watch(collectionRepoProvider);
  int _mutationVersion = 0;

  @override
  List<CardModel> build() {
    _loadInitialCards();
    return [];
  }

  Future<void> _loadInitialCards() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    final initialMutationVersion = _mutationVersion;

    try {
      final localRepository = await _getLocalRepository();
      final cachedCards = localRepository.getCards(userId);
      if (cachedCards.isNotEmpty &&
          _mutationVersion == initialMutationVersion) {
        state = cachedCards;
      }

      final remoteCards = await _repository.getCards();
      if (_mutationVersion == initialMutationVersion) {
        state = remoteCards;
        await localRepository.saveCards(userId, remoteCards);
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Karten: $e');
    }
  }

  Future<bool> addCards(List<CardModel> newCards) async {
    final previousState = state;
    _mutationVersion++;
    state = [...state, ...newCards];
    try {
      await _repository.addCards(newCards);
      await _saveLocalCards();
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
      _mutationVersion++;
      state = newState;

      try {
        await _repository.removeCard(cardId);
        await _saveLocalCards();
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
      _mutationVersion++;
      state = uniqueCards;
      try {
        await _repository.syncCollection(state);
        await _saveLocalCards();
        return true;
      } catch (e) {
        state = previousState;
        debugPrint('Fehler beim Synchronisieren der Sammlung: $e');
        return false;
      }
    }

    return true;
  }

  Future<LocalCollectionRepository> _getLocalRepository() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalCollectionRepository(preferences);
  }

  Future<void> _saveLocalCards() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    final localRepository = await _getLocalRepository();
    await localRepository.saveCards(userId, state);
  }
}

final collectionProvider =
    NotifierProvider<CollectionNotifier, List<CardModel>>(() {
      return CollectionNotifier();
    });
