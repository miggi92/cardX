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
  String get sportSoccer => 'Fussball';

  @override
  String get sportHandball => 'Handball';

  @override
  String get sportUnknown => 'Unbekannt';
}
