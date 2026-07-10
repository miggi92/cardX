import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/coin_repository.dart';
import '../repositories/local_coin_repository.dart';
import 'storage_provider.dart';

// 1. Der Repository-Provider (Hier wechselst du später einfach auf Supabase)
final coinRepositoryProvider = Provider<CoinRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return LocalCoinRepository(prefs);
});

// 2. Der angepasste Notifier
class CoinNotifier extends Notifier<int> {
  late final CoinRepository _repository = ref.watch(coinRepositoryProvider);

  @override
  int build() {
    return _repository.getCoins();
  }

  bool spendCoins(int amount) {
    if (state >= amount) {
      state -= amount;
      _repository.saveCoins(state);
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
