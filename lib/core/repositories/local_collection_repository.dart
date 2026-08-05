import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/cards/models/card_model.dart';

class LocalCollectionRepository {
  final SharedPreferences _prefs;
  static const _collectionKeyPrefix = 'user_collection';

  LocalCollectionRepository(this._prefs);

  List<CardModel> getCards(String userId) {
    final String? cardsJson = _prefs.getString(_collectionKey(userId));

    if (cardsJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(cardsJson);
        return decodedList
            .map((item) => CardModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } on FormatException {
        _prefs.remove(_collectionKey(userId));
      }
    }

    return [];
  }

  Future<void> saveCards(String userId, List<CardModel> cards) async {
    final String encodedList = jsonEncode(
      cards.map((card) => card.toJson()).toList(),
    );
    await _prefs.setString(_collectionKey(userId), encodedList);
  }

  String _collectionKey(String userId) => '$_collectionKeyPrefix.$userId';
}
