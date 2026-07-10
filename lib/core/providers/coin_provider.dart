import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/supabase_coin_repository.dart';

// Wir injizieren jetzt das Supabase-Repository
final coinRepoProvider = Provider((ref) => SupabaseCoinRepository());

class CoinNotifier extends Notifier<int> {
  late final _repository = ref.watch(coinRepoProvider);

  @override
  int build() {
    _loadInitialCoins();
    return 1000; // Platzhalter, während die echten Coins geladen werden
  }

  Future<void> _loadInitialCoins() async {
    try {
      state = await _repository.getCoins();
    } catch (e) {
      print("Fehler beim Laden der Coins: $e");
    }
  }

  bool spendCoins(int amount) {
    if (state >= amount) {
      state -= amount; // Optimistic Update (UI sofort anpassen)
      _repository.saveCoins(state); // Im Hintergrund an Supabase senden
      return true;
    }
    return false;
  }

  void addCoins(int amount) {
    state += amount;
    _repository.saveCoins(state);
  }
}

final coinProvider = NotifierProvider<CoinNotifier, int>(() {
  return CoinNotifier();
});
