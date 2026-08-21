import 'package:isar/isar.dart';

part 'app_settings_model.g.dart';

@collection
class AppSettingsModel {
  Id id = 1;

  String? customDownloadsPath;
  String audioQuality = 'High (320kbps)';
  bool gaplessPlayback = true;
  bool equalizerEnabled = false;
  String eqPreset = 'Flat';
  List<double> eqBandGains = [0.0, 0.0, 0.0, 0.0, 0.0];
  String theme = 'Deep Matte';
  bool animationsEnabled = true;
  bool isOfflineMode = false;
  List<String> dislikedSongIds = [];
  List<String> dislikedArtists = [];
}
