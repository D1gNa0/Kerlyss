import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KERLYSS'**
  String get appTitle;

  /// No description provided for @allTracks.
  ///
  /// In en, this message translates to:
  /// **'ALL TRACKS'**
  String get allTracks;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOADED'**
  String get downloaded;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'FAVORITES'**
  String get favorites;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'FOLDERS'**
  String get folders;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'NO FAVORITES YET'**
  String get noFavorites;

  /// No description provided for @noDownloaded.
  ///
  /// In en, this message translates to:
  /// **'NO DOWNLOADED TRACKS'**
  String get noDownloaded;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'LIBRARY EMPTY'**
  String get libraryEmpty;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylist;

  /// No description provided for @downloadFromLibrarySoon.
  ///
  /// In en, this message translates to:
  /// **'Library downloads will be available in a future update. Please use the Search feature to download tracks.'**
  String get downloadFromLibrarySoon;

  /// No description provided for @addedTo.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String addedTo(String name);

  /// No description provided for @stubNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Feature coming soon'**
  String get stubNotImplemented;

  /// No description provided for @previousShortcut.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousShortcut;

  /// No description provided for @nextShortcut.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextShortcut;

  /// No description provided for @back5s.
  ///
  /// In en, this message translates to:
  /// **'Back 5s'**
  String get back5s;

  /// No description provided for @forward5s.
  ///
  /// In en, this message translates to:
  /// **'Forward 5s'**
  String get forward5s;

  /// No description provided for @playPause.
  ///
  /// In en, this message translates to:
  /// **'Play/Pause'**
  String get playPause;

  /// No description provided for @pasteSpotifyLink.
  ///
  /// In en, this message translates to:
  /// **'PASTE SPOTIFY PLAYLIST LINK...'**
  String get pasteSpotifyLink;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'SEARCH SONGS, ARTISTS...'**
  String get searchPlaceholder;

  /// No description provided for @toggleSpotifyMode.
  ///
  /// In en, this message translates to:
  /// **'Toggle Spotify Import Mode'**
  String get toggleSpotifyMode;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
