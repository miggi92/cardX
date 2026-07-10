import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_provider.dart';

class CoinNotifier extends Notifier<int> {
  late final _prefs = ref.watch(sharedPrefsProvider);
  static const _coinsKey = 'user_coins';

  @override
  int build() {
    // Beim Start: Lade die Coins, oder gib 1000 als Startkapital
    return _prefs.getInt(_coinsKey) ?? 1000;
  }

  bool spendCoins(int amount) {
    if (state >= amount) {
      state -= amount;
      // Speichere den neuen Wert dauerhaft
      _prefs.setInt(_coinsKey, state);
      return true;
    }
    return false;
  }
}

final coinProvider = NotifierProvider<CoinNotifier, int>(() {
  return CoinNotifier();
});
