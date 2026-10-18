# Releasing Kerlyss (stable and beta)

The in-app updater only installs a release when ALL of these are true. Follow the order.

## Rules for version numbers
- Stable: `1.4.0`. Beta: `1.4.0-beta.1`, `1.4.0-beta.2`, ... A final `1.4.0` is newer than all its betas.
- Set the SAME value in `pubspec.yaml` (`version: 1.4.0-beta.1+15`) BEFORE building.
  If the build reports an older version, the app updates but still thinks it is old and offers the same update again forever.
  `make_release_metadata.ps1` checks the version inside the zip and refuses to continue when it does not match.
- The number after `+` (Android build number) MUST go up on EVERY build, stable or beta, and never go down.
  Android refuses to install a lower build number over a higher one (for example going from a beta back to stable).
- Always sign Android builds with the same key.

## Stable release
1. Build `Kerlyss-Android.apk` and `Kerlyss-Windows.zip` (the zip must contain `kerlyss.exe`).
2. Create a normal GitHub release tagged `v1.4.0` and upload both files with exactly those names.
3. Run `.\scripts\make_release_metadata.ps1 -Version 1.4.0 -Notes "..." -ApkPath <apk> -ZipPath <zip>`.
   It writes `version.json` and `checksums.txt`.
4. Commit and push those two files to `main` LAST. This is what makes the update visible to users.

## Beta release
1. Build the two files exactly like a stable release (version `1.4.0-beta.1` in `pubspec.yaml`).
2. Create a GitHub release tagged `v1.4.0-beta.1`, tick **"Set as a pre-release"**, upload both files with the same names.
3. Run `.\scripts\make_release_metadata.ps1 -Channel beta -Version 1.4.0-beta.1 -Notes "..." -ApkPath <apk> -ZipPath <zip>`.
   It writes `beta.json` and `checksums-beta.txt`. The stable files are NOT changed.
4. Commit and push those two files to `main` LAST.
5. Users with the stable app only get it through Settings -> "Check for Beta Updates". Nobody gets a beta automatically.

## Ending a beta
- Publish the stable release normally. Beta users get it through the normal "Check for Updates" (the stable check offers a final release over any beta).
- To switch the beta channel off, delete `beta.json` from `main` (the beta button then says "No newer beta is available right now").

## Windows: bundle the Visual C++ runtime (fixes "double click and nothing happens")
Flutter Windows apps need the Microsoft Visual C++ runtime. A PC without it cannot start `kerlyss.exe`.
Before zipping the Windows build, copy these 3 files into the same folder as `kerlyss.exe`
(`build\windows\x64\runner\Release`):
- `msvcp140.dll`
- `vcruntime140.dll`
- `vcruntime140_1.dll`
They are in `C:\Windows\System32` on a PC that has the "Microsoft Visual C++ 2015-2022 Redistributable (x64)" installed
(or in the Visual Studio folder `VC\Redist\MSVC\<version>\x64\Microsoft.VC143.CRT`).
If the app still does not start, it now writes `startup_error.log` (in the Kerlyss data folder) and opens it in Notepad.
