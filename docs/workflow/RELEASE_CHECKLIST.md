# Kerlyss v1.0.0 Release Checklist

## Code Quality Gates
- [ ] `flutter pub get` succeeds
- [ ] `flutter analyze` returns zero issues
- [ ] `flutter test` passes (all suites)
- [ ] CI workflow is green on the release commit

## Core Functional Validation
- [ ] Search returns results and tapping selected track plays correct song
- [ ] Deezer track resolution works from cache and cold lookup paths
- [ ] Playlist create/rename/add/remove flows behave correctly
- [ ] Download single and bulk flows complete and tracks replay locally
- [ ] Session restore resumes playlist/index/position without parse errors
- [ ] Next/Previous queue navigation behaves correctly during playback

## Failure Mode Validation
- [ ] DNS/network outage does not crash app (graceful errors)
- [ ] YouTube resolution failure shows controlled playback error state
- [ ] BPM lookup failure does not affect playback continuity

## Packaging and Artifacts
- [ ] `flutter build windows --release` succeeds
- [ ] `flutter build apk --release` succeeds
- [ ] Release notes prepared
- [ ] `checksums.txt` generated for artifacts
- [ ] Artifact filenames use `v1.0.0` naming convention

## Final Sign-off
- [ ] Version in `pubspec.yaml` is `1.0.0+1`
- [ ] Tag created: `v1.0.0`
- [ ] Smoke test on clean Windows machine
- [ ] Smoke test on clean Android device
