import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_provider.dart';

class DailyRewardNotifier extends Notifier<DateTime?> {
  late final _prefs = ref.watch(sharedPrefsProvider);
  static const _lastClaimKey = 'last_claim_date';

  @override
  DateTime? build() {
    final dateString = _prefs.getString(_lastClaimKey);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  bool get canClaim {
    if (state == null) return true;
    final now = DateTime.now();
    return state!.year != now.year ||
        state!.month != now.month ||
        state!.day != now.day;
  }

  void claimReward() {
    final now = DateTime.now();
    state = now;
    _prefs.setString(_lastClaimKey, now.toIso8601String());
  }
}

final dailyRewardProvider = NotifierProvider<DailyRewardNotifier, DateTime?>(
  () {
    return DailyRewardNotifier();
  },
);
