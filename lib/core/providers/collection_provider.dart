import 'dart:convert'; // Wichtig für jsonEncode / jsonDecode
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cards/models/card_model.dart';
import 'storage_provider.dart';

class CollectionNotifier extends Notifier<List<CardModel>> {
  late final _prefs = ref.watch(sharedPrefsProvider);
  static const _collectionKey = 'user_collection';

  @override
  List<CardModel> build() {
    // Beim Start: Versuche den gespeicherten JSON-String zu laden
    final String? cardsJson = _prefs.getString(_collectionKey);

    if (cardsJson != null) {
      // Wenn es Daten gibt: JSON in eine Liste von CardModels umwandeln
      final List<dynamic> decodedList = jsonDecode(cardsJson);
      return decodedList.map((item) => CardModel.fromJson(item)).toList();
    }

    return []; // Ansonsten mit leerer Sammlung starten
  }

  void addCards(List<CardModel> newCards) {
    // State aktualisieren (für das UI)
    state = [...state, ...newCards];

    // Neue Liste in JSON umwandeln und dauerhaft speichern
    final String encodedList = jsonEncode(
      state.map((card) => card.toJson()).toList(),
    );
    _prefs.setString(_collectionKey, encodedList);
  }

  void removeCard(String cardId) {
    // Finde die Position der ERSTEN Karte mit dieser ID
    final index = state.indexWhere((card) => card.id == cardId);

    if (index != -1) {
      // Erstelle eine Kopie der Liste, entferne die Karte und aktualisiere den State
      final newState = List<CardModel>.from(state);
      newState.removeAt(index);
      state = newState;

      // Neue Liste dauerhaft speichern
      final String encodedList = jsonEncode(
        state.map((card) => card.toJson()).toList(),
      );
      _prefs.setString(_collectionKey, encodedList);
    }
  }
}

final collectionProvider =
    NotifierProvider<CollectionNotifier, List<CardModel>>(() {
      return CollectionNotifier();
    });
