# UX & Feature Improvements Spec: Android Folder Picker, Custom Equalizer, Responsive Player Layout & Audio Info Panel

This specification details the design for resolving the issues raised by the Android reviewer regarding settings, folder picker, equalizer, and the Now Playing UI layout.

## Goals

1. **Folder Picker**: Replace the hardcoded download path launcher with a dynamic directory selector using the `file_picker` package, persistent via Isar database settings.
2. **Custom Equalizer**: Replace the stub presets dropdown with a fully functional 5-band Equalizer utilizing `just_audio`'s native Android effects, with custom sliders for gain adjustment and settings persistence.
3. **Responsive Now Playing Layout**: Redesign the `FullPlayerView` layout to dynamically distribute screen height, eliminating empty dead space on tall mobile devices.
4. **Audio Info Panel**: Display file size, audio format/codec, and average bitrate on the Now Playing screen (calculated for local files, retrieved from stream metadata for YouTube streams).

---

## 1. Persistent App Settings (Isar Schema)

To persist the selected download directory, EQ settings, and other app configurations, we will create a single-entry `AppSettingsModel` collection in Isar.

### `lib/data/models/app_settings_model.dart`
```dart
import 'package:isar/isar.dart';

part 'app_settings_model.g.dart';

@collection
class AppSettingsModel {
  Id id = 1; // Enforced single record

  String? customDownloadsPath;
  String audioQuality = 'High (320kbps)';
  bool gaplessPlayback = true;
  
  bool equalizerEnabled = false;
  String eqPreset = 'Flat';
  List<double> eqBandGains = [0.0, 0.0, 0.0, 0.0, 0.0]; // 5-band gains in dB

  String theme = 'Deep Matte';
  bool animationsEnabled = true;
}
```

---

## 2. Dynamic Download Folder Picker

We will integrate `file_picker` to let the user select any folder on their device and save it.

### `pubspec.yaml`
Add dependency:
```yaml
dependencies:
  file_picker: ^8.1.4
```

### Path Resolution
We will add `static String? _customDownloadsPath` to `AppStoragePaths`.
Upon app initialization in `main.dart`, we load settings from Isar and update `AppStoragePaths.customDownloadsPath = settings.customDownloadsPath`.
In `AppStoragePaths.downloadsDirectory()`:
```dart
  static Future<Directory> downloadsDirectory() async {
    if (_customDownloadsPath != null) {
      final dir = Directory(_customDownloadsPath!);
      if (await dir.exists()) return dir;
    }
    // Fallback to default path
  }
```

---

## 3. Custom Android Equalizer Integration

We will wire `AndroidEqualizer` from `just_audio` into the playback pipeline on Android.

### `KerlyssAudioHandler`
Initialize the equalizer conditionally and add it to the `AudioPipeline`:
```dart
final AndroidEqualizer? _equalizer = Platform.isAndroid ? AndroidEqualizer() : null;

// Inside AudioPlayer initialization:
audioPipeline: _equalizer != null ? AudioPipeline(androidAudioEffects: [_equalizer]) : null,
```

### UI Controls
On Settings -> Equalizer, we will build a dialog or sub-view presenting:
1. **Enable Switch**: Calls `_equalizer.setEnabled(value)`.
2. **Preset Dropdown**: (Flat, Bass Boost, Rock, etc.) that sets standard gains.
3. **5-Band Sliders**: If custom gains are adjusted, sets `_equalizer.parameters.bands[i].setGain(dbValue)` and updates `eqPreset` to "Custom".

---

## 4. Responsive Player Redesign

We will update `FullPlayerView` to distribute vertical space dynamically:
- Replace fixed spacers (`SizedBox(height: 24)`) with flexible spacers (`Spacer()` or `Expanded()`) wrapped in a `LayoutBuilder`.
- Use a `ConstrainedBox` for the visualizer/album art so it automatically scales down on smaller devices to prevent layout overflows.
- Align the remaining controls to fill the available screen area evenly.

---

## 5. Audio Info Panel

Expose audio characteristics on `AudioState` to display them on the Now Playing screen:

```dart
// in AudioState:
final String? audioFormat;
final String? audioBitrate;
final String? audioSize;
```

### Resolution Logic in `AudioNotifier`
- **Local Files**:
  Format = file extension.
  Size = `File(path).length()`.
  Bitrate = `(Size in Bytes * 8) / (Duration in ms)`.
- **YouTube/Spotify streams**:
  Retrieve the cached `StreamInfo` from `YoutubeProxyServer` using the resolved `videoId`.
  Size = `StreamInfo.size.totalBytes`.
  Bitrate = `StreamInfo.bitrate.bitsPerSecond`.
  Format = `StreamInfo.codec.subtype`.

---

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure all existing tests build and pass.
- Write unit tests verifying that settings load/save correctly from Isar and that custom download paths are properly cached by `AppStoragePaths`.
- Write unit tests for the bitrate and size formatting utility methods.

### Manual Verification
- Deploy to Android and verify that tapping "Downloads Folder" opens a directory picker.
- Toggle and adjust equalizer sliders and verify that the audio quality changes physically (e.g., bass boost increases low frequencies).
- Test on different device sizes and verify that the full player view scales without overflows or large gaps at the bottom.
