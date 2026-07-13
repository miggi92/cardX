import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('Fehler beim Laden der Coins: $e');
    }
  }

  Future<bool> spendCoins(int amount) async {
    if (state >= amount) {
      final previousState = state;
      state -= amount; // Optimistic Update (UI sofort anpassen)
      try {
        await _repository.saveCoins(state);
      } catch (e) {
        state = previousState;
        debugPrint('Fehler beim Speichern der Coins: $e');
        return false;
      }
      return true;
    }
    return false;
  }

  Future<bool> addCoins(int amount) async {
    final previousState = state;
    state += amount;
    try {
      await _repository.saveCoins(state);
      return true;
    } catch (e) {
      state = previousState;
      debugPrint('Fehler beim Speichern der Coins: $e');
      return false;
    }
  }
}

final coinProvider = NotifierProvider<CoinNotifier, int>(() {
  return CoinNotifier();
});
