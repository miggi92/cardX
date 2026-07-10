import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoinNotifier extends Notifier<int> {
  @override
  int build() {
    return 1000; // Dein Startkapital!
  }

  bool spendCoins(int amount) {
    if (state >= amount) {
      state -= amount; // Zieht die Coins ab und aktualisiert das UI automatisch
      return true; // Kauf erfolgreich
    }
    return false; // Zu wenig Coins
  }
}

final coinProvider = NotifierProvider<CoinNotifier, int>(() {
  return CoinNotifier();
});
