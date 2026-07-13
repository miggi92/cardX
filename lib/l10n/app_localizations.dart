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
/// import 'l10n/app_localizations.dart';
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
