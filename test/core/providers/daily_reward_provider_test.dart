import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardx/core/providers/daily_reward_provider.dart';
import 'package:cardx/core/repositories/supabase_coin_repository.dart';

class FakeSupabaseCoinRepository implements SupabaseCoinRepository {
  DateTime? lastFreePackDate;
  bool shouldThrowError = false;
  int coins = 0;

  @override
  Future<DateTime?> getLastFreePackDate() async {
    if (shouldThrowError) throw Exception('Simulated error');
    return lastFreePackDate;
  }

  @override
  Future<void> updateLastFreePackDate() async {
    if (shouldThrowError) throw Exception('Simulated error');
    lastFreePackDate = DateTime.now();
  }

  @override
  Future<int> getCoins() async {
    return coins;
  }

  @override
  Future<void> saveCoins(int amount) async {
    coins = amount;
  }
}

void main() {
  group('DailyRewardNotifier.canClaimFor', () {
    test('returns true when lastClaim is null', () {
      expect(DailyRewardNotifier.canClaimFor(null), isTrue);
    });

    test('returns true when lastClaim is yesterday', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      expect(DailyRewardNotifier.canClaimFor(yesterday), isTrue);
    });

    test('returns true when lastClaim is last month', () {
      final now = DateTime.now();
      // Handle edge cases like March 31 minus 1 month more cleanly
      // by just subtracting 30 days
      final lastMonth = now.subtract(const Duration(days: 30));
      expect(DailyRewardNotifier.canClaimFor(lastMonth), isTrue);
    });

    test('returns true when lastClaim is last year', () {
      final now = DateTime.now();
      final lastYear = DateTime(now.year - 1, now.month, now.day);
      expect(DailyRewardNotifier.canClaimFor(lastYear), isTrue);
    });

    test('returns false when lastClaim is today', () {
      expect(DailyRewardNotifier.canClaimFor(DateTime.now()), isFalse);
    });
  });

  group('DailyRewardNotifier', () {
    late ProviderContainer container;
    late FakeSupabaseCoinRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeSupabaseCoinRepository();
      container = ProviderContainer(
        overrides: [
          dailyRewardRepoProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('build() retrieves lastFreePackDate from repository', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      fakeRepo.lastFreePackDate = pastDate;

      final result = await container.read(dailyRewardProvider.future);
      expect(result, pastDate);
    });

    test('claimReward() succeeds and updates state when eligible', () async {
      // Simulate not having claimed yet
      fakeRepo.lastFreePackDate = null;

      // Await the initial build
      await container.read(dailyRewardProvider.future);

      final notifier = container.read(dailyRewardProvider.notifier);
      final result = await notifier.claimReward();

      expect(result, isTrue);
      // Repository date should have been updated
      expect(fakeRepo.lastFreePackDate, isNotNull);

      // State should reflect the update
      final state = container.read(dailyRewardProvider);
      expect(state.asData?.value, isNotNull);
      // Validate it's updated to today
      expect(state.asData!.value!.year, DateTime.now().year);
      expect(state.asData!.value!.month, DateTime.now().month);
      expect(state.asData!.value!.day, DateTime.now().day);
    });

    test('claimReward() fails and does not update state when already claimed today', () async {
      final now = DateTime.now();
      fakeRepo.lastFreePackDate = now;

      // Await initial build
      await container.read(dailyRewardProvider.future);

      // Keep a reference to the initial fake repo date to ensure it doesn't change
      final initialDateInRepo = fakeRepo.lastFreePackDate;

      final notifier = container.read(dailyRewardProvider.notifier);
      final result = await notifier.claimReward();

      expect(result, isFalse);

      // State and repo should remain exactly the same
      expect(fakeRepo.lastFreePackDate, initialDateInRepo);

      final state = container.read(dailyRewardProvider);
      expect(state.asData?.value, initialDateInRepo);
    });

    test('claimReward() fails and reverts state on repository error', () async {
      // Eligible to claim
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      fakeRepo.lastFreePackDate = yesterday;

      // Await initial build
      await container.read(dailyRewardProvider.future);
      final initialState = container.read(dailyRewardProvider);

      // Make the repository throw on update
      fakeRepo.shouldThrowError = true;

      final notifier = container.read(dailyRewardProvider.notifier);
      final result = await notifier.claimReward();

      expect(result, isFalse);

      // State should be reverted to original
      final finalState = container.read(dailyRewardProvider);
      expect(finalState.asData?.value, initialState.asData?.value);
    });
  });
}
