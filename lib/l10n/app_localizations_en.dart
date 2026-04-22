// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KERLYSS';

  @override
  String get allTracks => 'ALL TRACKS';

  @override
  String get downloaded => 'DOWNLOADED';

  @override
  String get favorites => 'FAVORITES';

  @override
  String get folders => 'FOLDERS';

  @override
  String get noFavorites => 'NO FAVORITES YET';

  @override
  String get noDownloaded => 'NO DOWNLOADED TRACKS';

  @override
  String get libraryEmpty => 'LIBRARY EMPTY';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get downloadFromLibrarySoon =>
      'Download from Library coming soon! Use Search to download for now.';

  @override
  String addedTo(String name) {
    return 'Added to $name';
  }

  @override
  String get stubNotImplemented => 'STUB — Not Implemented';

  @override
  String get previousShortcut => 'Previous (Ctrl + Left)';

  @override
  String get nextShortcut => 'Next (Ctrl + Right)';

  @override
  String get back5s => 'Back 5s (Left Arrow)';

  @override
  String get forward5s => 'Forward 5s (Right Arrow)';

  @override
  String get playPause => 'Play/Pause (Space)';

  @override
  String get pasteSpotifyLink => 'PASTE SPOTIFY PLAYLIST LINK...';

  @override
  String get searchPlaceholder => 'SEARCH SONGS, ARTISTS...';

  @override
  String get toggleSpotifyMode => 'Toggle Spotify Import Mode';

  @override
  String get download => 'Download';
}
