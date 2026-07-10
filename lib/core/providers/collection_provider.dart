import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cards/models/card_model.dart';
import '../repositories/collection_repository.dart';
import '../repositories/local_collection_repository.dart';
import 'storage_provider.dart';

// 1. Der Repository-Provider
final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return LocalCollectionRepository(prefs);
});

// 2. Der angepasste Notifier
class CollectionNotifier extends Notifier<List<CardModel>> {
  late final CollectionRepository _repository = ref.watch(
    collectionRepositoryProvider,
  );

  @override
  List<CardModel> build() {
    return _repository.getCards();
  }

  void addCards(List<CardModel> newCards) {
    state = [...state, ...newCards];
    _repository.saveCards(state);
  }

  void removeCard(String cardId) {
    final index = state.indexWhere((card) => card.id == cardId);

    if (index != -1) {
      final newState = List<CardModel>.from(state);
      newState.removeAt(index);
      state = newState;
      _repository.saveCards(state);
    }
  }
}

final collectionProvider =
    NotifierProvider<CollectionNotifier, List<CardModel>>(() {
      return CollectionNotifier();
    });
