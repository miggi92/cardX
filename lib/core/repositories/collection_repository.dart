import 'package:cardx/features/cards/models/card_model.dart';

abstract class CollectionRepository {
  List<CardModel> getCards();
  void saveCards(List<CardModel> cards);
}
