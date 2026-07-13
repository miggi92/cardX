import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'CardX Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardFreePackAlreadyClaimed.
  ///
  /// In en, this message translates to:
  /// **'You already claimed today\'s free pack.'**
  String get dashboardFreePackAlreadyClaimed;

  /// No description provided for @dashboardFreePackNoPlayersFound.
  ///
  /// In en, this message translates to:
  /// **'No players found for the free pack!'**
  String get dashboardFreePackNoPlayersFound;

  /// No description provided for @dashboardFreePackSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the free pack.'**
  String get dashboardFreePackSaveFailed;

  /// No description provided for @dashboardCardsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save cards.'**
  String get dashboardCardsSaveFailed;

  /// No description provided for @dashboardFreePackLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error while loading free pack: {error}'**
  String dashboardFreePackLoadError(Object error);

  /// No description provided for @dashboardDailyFreePackTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Free Pack'**
  String get dashboardDailyFreePackTitle;

  /// No description provided for @dashboardDailyFreePackAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'Get new players now and expand your collection.'**
  String get dashboardDailyFreePackAvailableBody;

  /// No description provided for @dashboardDailyFreePackUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Your free pack is already opened. Come back tomorrow for the next one.'**
  String get dashboardDailyFreePackUnavailableBody;

  /// No description provided for @dashboardOpenPackCta.
  ///
  /// In en, this message translates to:
  /// **'Open pack'**
  String get dashboardOpenPackCta;

  /// No description provided for @dashboardAvailableTomorrowCta.
  ///
  /// In en, this message translates to:
  /// **'Available again tomorrow'**
  String get dashboardAvailableTomorrowCta;

  /// No description provided for @dashboardCollectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get dashboardCollectionLabel;

  /// No description provided for @dashboardCoinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get dashboardCoinsLabel;

  /// No description provided for @dashboardCollectedCardsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String dashboardCollectedCardsCount(int count);

  /// No description provided for @dashboardProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get dashboardProgressTitle;

  /// No description provided for @dashboardCollectedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{collected} of {total} cards collected'**
  String dashboardCollectedOfTotal(int collected, int total);

  /// No description provided for @dashboardProgressBySportTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress by Sport'**
  String get dashboardProgressBySportTitle;

  /// No description provided for @dashboardSportsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading sports...'**
  String get dashboardSportsLoading;

  /// No description provided for @dashboardNoSportsFound.
  ///
  /// In en, this message translates to:
  /// **'No sports found.'**
  String get dashboardNoSportsFound;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @shopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pull new player cards and expand your collection.'**
  String get shopSubtitle;

  /// No description provided for @shopNoPlayersForPackFound.
  ///
  /// In en, this message translates to:
  /// **'No players found for this pack!'**
  String get shopNoPlayersForPackFound;

  /// No description provided for @shopPurchaseCanceledCoinsRefunded.
  ///
  /// In en, this message translates to:
  /// **'Purchase canceled, coins were refunded.'**
  String get shopPurchaseCanceledCoinsRefunded;

  /// No description provided for @shopPurchaseFailedNotEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed or not enough coins!'**
  String get shopPurchaseFailedNotEnoughCoins;

  /// No description provided for @shopPackTypeClub.
  ///
  /// In en, this message translates to:
  /// **'Club Pack'**
  String get shopPackTypeClub;

  /// No description provided for @shopPackTypeSport.
  ///
  /// In en, this message translates to:
  /// **'Sport Pack'**
  String get shopPackTypeSport;

  /// No description provided for @shopPackTypeLeague.
  ///
  /// In en, this message translates to:
  /// **'League Pack'**
  String get shopPackTypeLeague;

  /// No description provided for @shopPackTypeOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization Pack'**
  String get shopPackTypeOrganization;

  /// No description provided for @shopCoinsCount.
  ///
  /// In en, this message translates to:
  /// **'{coins} Coins'**
  String shopCoinsCount(int coins);

  /// No description provided for @shopCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String shopCategoryLabel(Object category);

  /// No description provided for @shopOpenForCoins.
  ///
  /// In en, this message translates to:
  /// **'Open for {coins} coins'**
  String shopOpenForCoins(int coins);

  /// No description provided for @shopCoinsRequired.
  ///
  /// In en, this message translates to:
  /// **'{coins} coins required'**
  String shopCoinsRequired(int coins);

  /// No description provided for @shopLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error while loading the shop:\n{error}'**
  String shopLoadError(Object error);

  /// No description provided for @shopPacksAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} packs available'**
  String shopPacksAvailable(int count);

  /// No description provided for @collectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection ({count} total)'**
  String collectionTitle(int count);

  /// No description provided for @collectionSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search players...'**
  String get collectionSearchHint;

  /// No description provided for @collectionSellCardFailed.
  ///
  /// In en, this message translates to:
  /// **'Card could not be sold.'**
  String get collectionSellCardFailed;

  /// No description provided for @collectionCreditCoinsFailed.
  ///
  /// In en, this message translates to:
  /// **'Coins could not be credited.'**
  String get collectionCreditCoinsFailed;

  /// No description provided for @collectionSoldCardForCoins.
  ///
  /// In en, this message translates to:
  /// **'{playerName} ({rarity}) sold for {coins} coins!'**
  String collectionSoldCardForCoins(
    Object playerName,
    Object rarity,
    int coins,
  );

  /// No description provided for @collectionQuickSellWithValue.
  ///
  /// In en, this message translates to:
  /// **'Quick Sell (+{value})'**
  String collectionQuickSellWithValue(int value);

  /// No description provided for @collectionLastCopy.
  ///
  /// In en, this message translates to:
  /// **'Last copy'**
  String get collectionLastCopy;

  /// No description provided for @collectionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get collectionClose;

  /// No description provided for @collectionSellAllDuplicatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell all duplicates?'**
  String get collectionSellAllDuplicatesTitle;

  /// No description provided for @collectionSellAllDuplicatesBody.
  ///
  /// In en, this message translates to:
  /// **'You are about to sell {duplicateCount} duplicate cards. You will receive {totalValue} coins.'**
  String collectionSellAllDuplicatesBody(int duplicateCount, int totalValue);

  /// No description provided for @collectionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get collectionCancel;

  /// No description provided for @collectionSellDuplicatesFailed.
  ///
  /// In en, this message translates to:
  /// **'Duplicates could not be sold.'**
  String get collectionSellDuplicatesFailed;

  /// No description provided for @collectionSoldDuplicatesForCoins.
  ///
  /// In en, this message translates to:
  /// **'{duplicateCount} cards sold for {totalValue} coins!'**
  String collectionSoldDuplicatesForCoins(int duplicateCount, int totalValue);

  /// No description provided for @collectionSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get collectionSell;

  /// No description provided for @collectionAllFilter.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get collectionAllFilter;

  /// No description provided for @collectionSellAllDuplicatesCta.
  ///
  /// In en, this message translates to:
  /// **'Sell all duplicates (+ {coins} coins)'**
  String collectionSellAllDuplicatesCta(int coins);

  /// No description provided for @collectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your collection is still empty.'**
  String get collectionEmpty;

  /// No description provided for @collectionNoPlayersFound.
  ///
  /// In en, this message translates to:
  /// **'No players found.'**
  String get collectionNoPlayersFound;

  /// No description provided for @collectionPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String collectionPlayersCount(int count);

  /// No description provided for @collectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get collectionGeneral;

  /// No description provided for @rarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get rarityCommon;

  /// No description provided for @rarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get rarityRare;

  /// No description provided for @rarityEpic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get rarityEpic;

  /// No description provided for @rarityLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get rarityLegendary;

  /// No description provided for @sportSoccer.
  ///
  /// In en, this message translates to:
  /// **'Soccer'**
  String get sportSoccer;

  /// No description provided for @sportHandball.
  ///
  /// In en, this message translates to:
  /// **'Handball'**
  String get sportHandball;

  /// No description provided for @sportUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get sportUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
