// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dashboardTitle => 'CardX Dashboard';

  @override
  String get dashboardFreePackAlreadyClaimed =>
      'You already claimed today\'s free pack.';

  @override
  String get dashboardFreePackNoPlayersFound =>
      'No players found for the free pack!';

  @override
  String get dashboardFreePackSaveFailed => 'Could not save the free pack.';

  @override
  String get dashboardCardsSaveFailed => 'Could not save cards.';

  @override
  String dashboardFreePackLoadError(Object error) {
    return 'Error while loading free pack: $error';
  }

  @override
  String get dashboardDailyFreePackTitle => 'Daily Free Pack';

  @override
  String get dashboardDailyFreePackAvailableBody =>
      'Get new players now and expand your collection.';

  @override
  String get dashboardDailyFreePackUnavailableBody =>
      'Your free pack is already opened. Come back tomorrow for the next one.';

  @override
  String get dashboardOpenPackCta => 'Open pack';

  @override
  String get dashboardAvailableTomorrowCta => 'Available again tomorrow';

  @override
  String get dashboardCollectionLabel => 'Collection';

  @override
  String get dashboardCoinsLabel => 'Coins';

  @override
  String dashboardCollectedCardsCount(int count) {
    return '$count cards';
  }

  @override
  String get dashboardProgressTitle => 'Your Progress';

  @override
  String dashboardCollectedOfTotal(int collected, int total) {
    return '$collected of $total cards collected';
  }

  @override
  String get dashboardProgressBySportTitle => 'Progress by Sport';

  @override
  String get dashboardSportsLoading => 'Loading sports...';

  @override
  String get dashboardNoSportsFound => 'No sports found.';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopSubtitle =>
      'Pull new player cards and expand your collection.';

  @override
  String get shopNoPlayersForPackFound => 'No players found for this pack!';

  @override
  String get shopPurchaseCanceledCoinsRefunded =>
      'Purchase canceled, coins were refunded.';

  @override
  String get shopPurchaseFailedNotEnoughCoins =>
      'Purchase failed or not enough coins!';

  @override
  String get shopPackTypeClub => 'Club Pack';

  @override
  String get shopPackTypeSport => 'Sport Pack';

  @override
  String get shopPackTypeLeague => 'League Pack';

  @override
  String get shopPackTypeOrganization => 'Organization Pack';

  @override
  String shopCoinsCount(int coins) {
    return '$coins Coins';
  }

  @override
  String shopCategoryLabel(Object category) {
    return 'Category: $category';
  }

  @override
  String shopOpenForCoins(int coins) {
    return 'Open for $coins coins';
  }

  @override
  String shopCoinsRequired(int coins) {
    return '$coins coins required';
  }

  @override
  String shopLoadError(Object error) {
    return 'Error while loading the shop:\n$error';
  }

  @override
  String shopPacksAvailable(int count) {
    return '$count packs available';
  }

  @override
  String collectionTitle(int count) {
    return 'Collection ($count total)';
  }

  @override
  String get collectionSearchHint => 'Search players...';

  @override
  String get collectionSellCardFailed => 'Card could not be sold.';

  @override
  String get collectionCreditCoinsFailed => 'Coins could not be credited.';

  @override
  String collectionSoldCardForCoins(
    Object playerName,
    Object rarity,
    int coins,
  ) {
    return '$playerName ($rarity) sold for $coins coins!';
  }

  @override
  String collectionQuickSellWithValue(int value) {
    return 'Quick Sell (+$value)';
  }

  @override
  String get collectionLastCopy => 'Last copy';

  @override
  String get collectionClose => 'Close';

  @override
  String get collectionSellAllDuplicatesTitle => 'Sell all duplicates?';

  @override
  String collectionSellAllDuplicatesBody(int duplicateCount, int totalValue) {
    return 'You are about to sell $duplicateCount duplicate cards. You will receive $totalValue coins.';
  }

  @override
  String get collectionCancel => 'Cancel';

  @override
  String get collectionSellDuplicatesFailed => 'Duplicates could not be sold.';

  @override
  String collectionSoldDuplicatesForCoins(int duplicateCount, int totalValue) {
    return '$duplicateCount cards sold for $totalValue coins!';
  }

  @override
  String get collectionSell => 'Sell';

  @override
  String get collectionAllFilter => 'ALL';

  @override
  String collectionSellAllDuplicatesCta(int coins) {
    return 'Sell all duplicates (+ $coins coins)';
  }

  @override
  String get collectionEmpty => 'Your collection is still empty.';

  @override
  String get collectionNoPlayersFound => 'No players found.';

  @override
  String collectionPlayersCount(int count) {
    return '$count players';
  }

  @override
  String get collectionGeneral => 'General';

  @override
  String get sportSoccer => 'Soccer';

  @override
  String get sportHandball => 'Handball';

  @override
  String get sportUnknown => 'Unknown';
}
