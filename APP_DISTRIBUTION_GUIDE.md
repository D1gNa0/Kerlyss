# 🚀 Kerlyss: Distribution & Versioning Strategy

This document outlines the professional workflow for the private development and public "sideloaded" distribution of the Kerlyss music app, ensuring a seamless transition to the Google Play Store in the future.

---

## 1. Repository Strategy

We maintain a strict separation between source code and public distribution to protect intellectual property and API secrets.

### 🔒 Private Repository (`kerlyss-private`)
- **Purpose:** Core development and source of truth.
- **Content:** Full Flutter source code, sensitive API keys, assets, and internal documentation.
- **Rule:** Never made public.

### 📢 Public Repository (`kerlyss-distribution`)
- **Purpose:** User-facing hub and download center.
- **Content:** - **Releases:** Compiled APK/App Bundle files.
    - **Issue Tracker:** For user bug reports and feature requests.
    - **Documentation:** README, Changelog, and Installation guides.
- **Rule:** No source code is ever pushed here.

---

## 2. Versioning Strategy (SemVer)

We follow **Semantic Versioning** (MAJOR.MINOR.PATCH) to track compatibility and features.

### Internal (Private)
- **Format:** `dev-X.Y.Z` (e.g., `dev-0.9.4`)
- Used for internal milestones and beta testing among the development team.

### Public (Production)
- **First Release:** `v1.0.0`
- **Rule:** Public versions must always increment. Never "recycle" a version number once an APK has been distributed.

---

## 3. Production Build & Security

### Building for Android
To prevent reverse engineering of our music-fetching logic, we use obfuscation.

```bash
flutter build apk --release --obfuscate --split-debug-info=symbols/
```

### 🔑 IMPORTANT: App Signing
You must create a **Keystore file** immediately. 
- Use the **SAME** keystore for the GitHub APK and the future Play Store upload.
- If the signatures don't match, Android will block users from updating the app.
- **Backup this file and its password in multiple secure locations.**

---

## 4. GitHub Release Workflow

1. **Tagging:** Create a tag in the public repo (e.g., `v1.0.2`).
2. **Binary Upload:** Attach the `app-release.apk` to the Release notes.
3. **Naming Convention:** `kerlyss-v1.0.2-android.apk`.
4. **Changelog:** Provide a clear "What's New" section for the users.

---

## 5. Built-in Update Logic (The "Bridge" Strategy)

To ensure users stay on the latest version without an App Store, Kerlyss will include a custom update checker.

### Current Logic (Pre-Play Store):
1. On startup, the app fetches a `version.json` from the public GitHub repo.
2. If `localVersion < remoteVersion`, show a non-intrusive update prompt.
3. Direct the user to the GitHub Releases page.

### Future Logic (Play Store Transition):
- **Detection:** The app will check the "Installer Store." 
- **Behavior:** If the app was installed via `com.android.vending` (Google Play), the custom update checker **must be disabled** to comply with Google’s "No Self-Update" policy.

---

## 6. Monetization Approach

Since Kerlyss is distributed as an APK initially, we bypass the 30% "Apple/Google Tax."

- **Provider:** Use **Stripe** or **LemonSqueezy** via a web-view or external browser link.
- **Workflow:** 1. User clicks "Go Premium" in the app.
    2. Opens a browser to `checkout.kerlyss.com`.
    3. User pays via Credit Card/Apple Pay.
    4. Backend updates the User's ID; the app unlocks features upon next sync.

---

## 7. README / User Installation Guide

### 📥 Download
Always download the latest official APK from our [Releases Page].

### 🛠️ Installation Instructions
1. Download the `kerlyss-vX.X.X.apk` file.
2. Open your Android "Settings" and search for **"Install Unknown Apps"**.
3. Grant permission to your Browser or File Manager.
4. Tap the APK file and select **Install**.

### ⚠️ Security Note
Because Kerlyss is not yet on the Play Store, you may see a **"Play Protect"** warning. This is normal for independent APKs. You can click "Install Anyway" to proceed.

---

## 8. Summary Development Lifecycle

1. **Code:** Build features in `kerlyss-private`.
2. **Test:** Run integration tests for Spotify/YouTube streams.
3. **Build:** Generate the obfuscated APK with the production Keystore.
4. **Release:** Draft a new release in `kerlyss-distribution` and upload the APK.
5. **Monitor:** Check the public Issue Tracker for user feedback.
6. **Pivot:** When the user base hits a significant milestone, submit the `App Bundle` (.aab) to the Google Play Console.