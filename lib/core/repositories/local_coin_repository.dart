import 'package:shared_preferences/shared_preferences.dart';
import 'coin_repository.dart';

class LocalCoinRepository implements CoinRepository {
  final SharedPreferences _prefs;
  static const _coinsKey = 'user_coins';

  LocalCoinRepository(this._prefs);

  @override
  int getCoins() {
    return _prefs.getInt(_coinsKey) ?? 1000;
  }

  @override
  void saveCoins(int amount) {
    _prefs.setInt(_coinsKey, amount);
  }
}
