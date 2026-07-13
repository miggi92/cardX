import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/supabase_coin_repository.dart';

final dailyRewardRepoProvider = Provider((ref) => SupabaseCoinRepository());

class DailyRewardNotifier extends AsyncNotifier<DateTime?> {
  late final _repository = ref.watch(dailyRewardRepoProvider);

  @override
  Future<DateTime?> build() async {
    return _repository.getLastFreePackDate();
  }

  static bool canClaimFor(DateTime? lastClaim) {
    if (lastClaim == null) return true;
    final now = DateTime.now();
    return lastClaim.year != now.year ||
        lastClaim.month != now.month ||
        lastClaim.day != now.day;
  }

  Future<bool> claimReward() async {
    final lastClaim = state.asData?.value;
    if (!canClaimFor(lastClaim)) {
      return false;
    }

    final previousState = state;
    final now = DateTime.now();
    state = AsyncData(now);

    try {
      await _repository.updateLastFreePackDate();
      return true;
    } catch (_) {
      state = previousState;
      return false;
    }
  }
}

final dailyRewardProvider =
    AsyncNotifierProvider<DailyRewardNotifier, DateTime?>(() {
      return DailyRewardNotifier();
    });
