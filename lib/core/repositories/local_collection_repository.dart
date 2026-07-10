import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/cards/models/card_model.dart';
import 'collection_repository.dart';

class LocalCollectionRepository implements CollectionRepository {
  final SharedPreferences _prefs;
  static const _collectionKey = 'user_collection';

  LocalCollectionRepository(this._prefs);

  @override
  List<CardModel> getCards() {
    final String? cardsJson = _prefs.getString(_collectionKey);

    if (cardsJson != null) {
      final List<dynamic> decodedList = jsonDecode(cardsJson);
      return decodedList.map((item) => CardModel.fromJson(item)).toList();
    }

    return [];
  }

  @override
  void saveCards(List<CardModel> cards) {
    final String encodedList = jsonEncode(
      cards.map((card) => card.toJson()).toList(),
    );
    _prefs.setString(_collectionKey, encodedList);
  }
}
