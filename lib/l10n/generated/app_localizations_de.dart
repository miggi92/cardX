// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get dashboardTitle => 'CardX Dashboard';

  @override
  String get dashboardFreePackAlreadyClaimed =>
      'Gratis-Pack heute bereits abgeholt.';

  @override
  String get dashboardFreePackNoPlayersFound =>
      'Keine Spieler fur das Gratis-Pack gefunden!';

  @override
  String get dashboardFreePackSaveFailed =>
      'Gratis-Pack konnte nicht gespeichert werden.';

  @override
  String get dashboardCardsSaveFailed =>
      'Karten konnten nicht gespeichert werden.';

  @override
  String dashboardFreePackLoadError(Object error) {
    return 'Fehler beim Laden des Gratis-Packs: $error';
  }

  @override
  String get dashboardDailyFreePackTitle => 'Tagliches Gratis-Pack';

  @override
  String get dashboardDailyFreePackAvailableBody =>
      'Hol dir jetzt neue Spieler und erweitere deine Sammlung.';

  @override
  String get dashboardDailyFreePackUnavailableBody =>
      'Dein Gratis-Pack ist bereits geoffnet. Komm morgen fur das nachste zuruck.';

  @override
  String get dashboardOpenPackCta => 'Pack offnen';

  @override
  String get dashboardAvailableTomorrowCta => 'Morgen wieder verfugbar';

  @override
  String get dashboardCollectionLabel => 'Sammlung';

  @override
  String get dashboardCoinsLabel => 'Coins';

  @override
  String dashboardCollectedCardsCount(int count) {
    return '$count Karten';
  }

  @override
  String get dashboardProgressTitle => 'Dein Fortschritt';

  @override
  String dashboardCollectedOfTotal(int collected, int total) {
    return '$collected von $total Karten gesammelt';
  }

  @override
  String get dashboardProgressBySportTitle => 'Fortschritt pro Sportart';

  @override
  String get dashboardSportsLoading => 'Sportarten werden geladen ...';

  @override
  String get dashboardNoSportsFound => 'Keine Sportarten gefunden.';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopSubtitle =>
      'Ziehe neue Spielerkarten und erweitere deine Sammlung.';

  @override
  String get shopNoPlayersForPackFound =>
      'Keine Spieler fur dieses Pack gefunden!';

  @override
  String get shopPurchaseCanceledCoinsRefunded =>
      'Kauf abgebrochen, Coins wurden erstattet.';

  @override
  String get shopPurchaseFailedNotEnoughCoins =>
      'Kauf fehlgeschlagen oder nicht genug Coins!';

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
    return 'Kategorie: $category';
  }

  @override
  String shopOpenForCoins(int coins) {
    return 'Fur $coins Coins offnen';
  }

  @override
  String shopCoinsRequired(int coins) {
    return '$coins Coins benotigt';
  }

  @override
  String shopLoadError(Object error) {
    return 'Fehler beim Laden des Shops:\n$error';
  }

  @override
  String shopPacksAvailable(int count) {
    return '$count Packs verfugbar';
  }

  @override
  String collectionTitle(int count) {
    return 'Sammlung ($count gesamt)';
  }

  @override
  String get collectionSearchHint => 'Spieler suchen...';

  @override
  String get collectionSellCardFailed => 'Karte konnte nicht verkauft werden.';

  @override
  String get collectionCreditCoinsFailed =>
      'Coins konnten nicht gutgeschrieben werden.';

  @override
  String collectionSoldCardForCoins(
    Object playerName,
    Object rarity,
    int coins,
  ) {
    return '$playerName ($rarity) verkauft fur $coins Coins!';
  }

  @override
  String collectionQuickSellWithValue(int value) {
    return 'Quick Sell (+$value)';
  }

  @override
  String get collectionLastCopy => 'Letztes Exemplar';

  @override
  String get collectionClose => 'Schließen';

  @override
  String get collectionSellAllDuplicatesTitle => 'Alle Duplikate verkaufen?';

  @override
  String collectionSellAllDuplicatesBody(int duplicateCount, int totalValue) {
    return 'Du stehst kurz davor, $duplicateCount doppelte Karten zu verkaufen. Dafur erhaltst du $totalValue Coins.';
  }

  @override
  String get collectionCancel => 'Abbrechen';

  @override
  String get collectionSellDuplicatesFailed =>
      'Duplikate konnten nicht verkauft werden.';

  @override
  String collectionSoldDuplicatesForCoins(int duplicateCount, int totalValue) {
    return '$duplicateCount Karten fur $totalValue Coins verkauft!';
  }

  @override
  String get collectionSell => 'Verkaufen';

  @override
  String get collectionAllFilter => 'ALLE';

  @override
  String collectionSellAllDuplicatesCta(int coins) {
    return 'Alle doppelten verkaufen (+ $coins Coins)';
  }

  @override
  String get collectionEmpty => 'Deine Sammlung ist noch leer.';

  @override
  String get collectionNoPlayersFound => 'Keine Spieler gefunden.';

  @override
  String collectionPlayersCount(int count) {
    return '$count Spieler';
  }

  @override
  String get collectionGeneral => 'Allgemein';

  @override
  String get sportSoccer => 'Fußball';

  @override
  String get sportHandball => 'Handball';

  @override
  String get sportUnknown => 'Unbekannt';
}
