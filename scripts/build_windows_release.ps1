param (
    [string]$CertPassword = "YourStrongPassword123!",
    [string]$CertSubject = "CN=Kerlyss",
    [string]$CertPath = ".\kerlyss_cert.pfx"
)

Write-Host "Starting Windows Release Build and Signing Process..." -ForegroundColor Cyan

# Step 1: Check if certificate exists, generate if not
if (-not (Test-Path $CertPath)) {
    Write-Host "Certificate not found at $CertPath. Generating a new self-signed certificate..." -ForegroundColor Yellow
    
    # Create the certificate
    $cert = New-SelfSignedCertificate -Type Custom -Subject $CertSubject -KeyUsage DigitalSignature -FriendlyName "Kerlyss Code Sign" -CertStoreLocation "Cert:\CurrentUser\My" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3")
    
    # Export it to a .pfx file
    $password = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath $CertPath -Password $password | Out-Null
    
    Write-Host "Certificate generated successfully at $CertPath" -ForegroundColor Green
} else {
    Write-Host "Using existing certificate at $CertPath" -ForegroundColor Green
}

# Step 2: Build Flutter Windows App
Write-Host "Building Flutter Windows App (Release)..." -ForegroundColor Yellow
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter build failed. Aborting."
    exit $LASTEXITCODE
}

$ExePath = "build\windows\x64\runner\Release\kerlyss.exe"

if (-not (Test-Path $ExePath)) {
    Write-Error "Could not find compiled executable at $ExePath"
    exit 1
}

# Step 3: Find signtool.exe and Sign the .exe
Write-Host "Locating signtool.exe..." -ForegroundColor Yellow
$SignToolPath = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\10\bin" -Filter "signtool.exe" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "\\x64\\" } | Select-Object -First 1 -ExpandProperty FullName

if ([string]::IsNullOrWhiteSpace($SignToolPath)) {
    Write-Error "Could not find signtool.exe. Please ensure Windows SDK is installed."
    exit 1
}

Write-Host "Found signtool at: $SignToolPath"
Write-Host "Signing the executable..." -ForegroundColor Yellow

# Execute signtool
& $SignToolPath sign /f $CertPath /p $CertPassword /tr http://timestamp.digicert.com /td sha256 /fd sha256 $ExePath

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success! The executable at $ExePath has been signed." -ForegroundColor Green
} else {
    Write-Error "Signing failed."
    exit $LASTEXITCODE
}
