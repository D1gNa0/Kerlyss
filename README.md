# Kerlyss - Modern Music Streaming & Library Player

🌐 **Official Website:** [d1gna0.github.io/Kerlyss](https://d1gna0.github.io/Kerlyss/)

---

## 📥 Download & Install

The latest version can always be found on our **[Releases Page](https://github.com/D1gNa0/Kerlyss/releases/latest)**.

### Android Installation

1.  Download the `kerlyss-vX.X.X-android.apk` file from the latest release.
2.  Open your Android "Settings" and search for **"Install Unknown Apps"**.
3.  Grant permission to your Browser (e.g., Chrome) or your File Manager app.
4.  Tap the downloaded `.apk` file and select **Install**.

> **⚠️ Security Note**
> Because Kerlyss is not yet on the Google Play Store, you may see a **"Play Protect"** warning during installation. This is normal for independently distributed apps. You can safely click "More details" and then **"Install Anyway"** to proceed.

### Windows Installation

1.  Download the `kerlyss-vX.X.X-windows.zip` file from the latest release.
2.  Extract the contents of the `.zip` file to a permanent folder (e.g., `C:\Program Files\Kerlyss`).
3.  Run `kerlyss.exe` to start the application.

---

## ✅ Verifying Authenticity (Checksums)

To ensure the file you downloaded has not been tampered with, you can verify its SHA-256 checksum. Each release includes a `checksums.txt` file.

#### On Windows (PowerShell):
```powershell
Get-FileHash kerlyss-vX.X.X-android.apk -Algorithm SHA256
```

#### On macOS / Linux:
```bash
shasum -a 256 kerlyss-vX.X.X-android.apk
```

Compare the output hash with the one listed in `checksums.txt`. They must match exactly.
