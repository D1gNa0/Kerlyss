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
    [Parameter(Mandatory = $true)][string]$ZipPath,
    # Only for emergencies: skips the check that kerlyss.exe inside the zip reports -Version.
    [switch]$SkipVersionCheck
)

if ($Channel -eq 'beta' -and $Version -notmatch '-') {
    Write-Error "A beta version must contain a pre-release tag, for example 1.4.0-beta.1"
    exit 1
}
if ($Channel -eq 'stable' -and $Version -match '-') {
    Write-Error "A stable version must not contain a pre-release tag (no '-')."
    exit 1
}

# SAFETY CHECK: kerlyss.exe inside the zip must report the version we are about to publish.
# If it reports an older version (pubspec.yaml was not bumped before building), the app
# updates, still thinks it is old, and offers the same update again forever.
if (-not $SkipVersionCheck) {
    $verifyDir = Join-Path ([System.IO.Path]::GetTempPath()) ('kerlyss_verify_' + [guid]::NewGuid().ToString('N'))
    try {
        Expand-Archive -LiteralPath $ZipPath -DestinationPath $verifyDir -Force
        $exe = Get-ChildItem -LiteralPath $verifyDir -Recurse -Filter 'kerlyss.exe' | Select-Object -First 1
        if (-not $exe) {
            Write-Error "kerlyss.exe was not found inside $ZipPath"
            exit 1
        }
        $built = ([string]$exe.VersionInfo.ProductVersion).Split('+')[0].Trim()
        if ($built -ne $Version) {
            Write-Error "kerlyss.exe in the zip reports version '$built' but you are publishing '$Version'. Set 'version: $Version+<build number>' in pubspec.yaml, rebuild, and zip again. (Use -SkipVersionCheck to ignore this.)"
            exit 1
        }
        Write-Host "Version check OK: kerlyss.exe reports $built" -ForegroundColor Green
    } finally {
        Remove-Item -LiteralPath $verifyDir -Recurse -Force -ErrorAction SilentlyContinue
    }
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

# Write UTF-8 WITHOUT a BOM (Windows PowerShell's "-Encoding utf8" adds a BOM, which breaks JSON parsing).
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $PWD.Path $checksumsFile), $checksums, $utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path $PWD.Path $jsonFile), $json, $utf8NoBom)

Write-Host "Wrote $checksumsFile and $jsonFile for v$Version ($Channel)" -ForegroundColor Green
Write-Host "Android: $apkHash"
Write-Host "Windows: $zipHash"
