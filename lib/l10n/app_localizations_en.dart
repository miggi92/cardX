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
  String get sportSoccer => 'Soccer';

  @override
  String get sportHandball => 'Handball';

  @override
  String get sportUnknown => 'Unknown';
}
