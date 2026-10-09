# Generates checksums.txt + version.json for a release so the in-app updater accepts it.
# Usage (from the repo root, after building both release files):
#   .\scripts\make_release_metadata.ps1 -Version 1.3.4 -Notes "What's new..." `
#       -ApkPath .\build\app\outputs\flutter-apk\app-release.apk -ZipPath .\Kerlyss-Windows.zip
# Then upload the APK as `Kerlyss-Android.apk` and the zip as `Kerlyss-Windows.zip` to the GitHub
# release v<Version>, and commit checksums.txt + version.json to main.
param (
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Notes,
    [Parameter(Mandatory = $true)][string]$ApkPath,
    [Parameter(Mandatory = $true)][string]$ZipPath
)

$apkHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ApkPath).Hash
$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ZipPath).Hash

$checksums = @"
Kerlyss Release Binary Checksums (SHA-256)
==============================================
Release Version: v$Version
Build Date: $(Get-Date -Format yyyy-MM-dd)

$apkHash  Kerlyss-Android.apk
$zipHash  Kerlyss-Windows.zip
"@
Set-Content -LiteralPath "checksums.txt" -Value $checksums -Encoding utf8

$json = [ordered]@{ version = $Version; releaseNotes = $Notes } | ConvertTo-Json
Set-Content -LiteralPath "version.json" -Value $json -Encoding utf8

Write-Host "Wrote checksums.txt and version.json for v$Version" -ForegroundColor Green
Write-Host "Android: $apkHash"
Write-Host "Windows: $zipHash"
