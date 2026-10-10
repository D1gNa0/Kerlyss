# Generates the metadata files the in-app updater needs.
#
# STABLE release (writes checksums.txt + version.json):
#   .\scripts\make_release_metadata.ps1 -Version 1.4.0 -Notes "What's new..." `
#       -ApkPath .\build\app\outputs\flutter-apk\app-release.apk -ZipPath .\Kerlyss-Windows.zip
#
# BETA release (writes checksums-beta.txt + beta.json, stable files are NOT touched):
#   .\scripts\make_release_metadata.ps1 -Channel beta -Version 1.4.0-beta.1 -Notes "Testing X" `
#       -ApkPath .\build\app\outputs\flutter-apk\app-release.apk -ZipPath .\Kerlyss-Windows.zip
#
# Then upload the APK as `Kerlyss-Android.apk` and the zip as `Kerlyss-Windows.zip` to the GitHub
# release tagged v<Version> (for a beta, tick "Set as a pre-release"), and commit the generated
# files to main LAST. See scripts/RELEASING.md.
param (
    [ValidateSet('stable', 'beta')][string]$Channel = 'stable',
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Notes,
    [Parameter(Mandatory = $true)][string]$ApkPath,
    [Parameter(Mandatory = $true)][string]$ZipPath
)

if ($Channel -eq 'beta' -and $Version -notmatch '-') {
    Write-Error "A beta version must contain a pre-release tag, for example 1.4.0-beta.1"
    exit 1
}
if ($Channel -eq 'stable' -and $Version -match '-') {
    Write-Error "A stable version must not contain a pre-release tag (no '-')."
    exit 1
}

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

if ($Channel -eq 'beta') {
    $checksumsFile = 'checksums-beta.txt'
    $jsonFile = 'beta.json'
    $json = [ordered]@{ version = $Version; tag = "v$Version"; releaseNotes = $Notes } | ConvertTo-Json
} else {
    $checksumsFile = 'checksums.txt'
    $jsonFile = 'version.json'
    $json = [ordered]@{ version = $Version; releaseNotes = $Notes } | ConvertTo-Json
}

Set-Content -LiteralPath $checksumsFile -Value $checksums -Encoding utf8
Set-Content -LiteralPath $jsonFile -Value $json -Encoding utf8

Write-Host "Wrote $checksumsFile and $jsonFile for v$Version ($Channel)" -ForegroundColor Green
Write-Host "Android: $apkHash"
Write-Host "Windows: $zipHash"
