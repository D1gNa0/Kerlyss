Structure and Purpose: 


# 🎵 Project Kerlyss: Unified Music Architecture

## 1. Vision & Purpose
**Kerlyss** is a high-performance, cross-platform audio ecosystem designed to solve "Library Fragmentation." 

### The Problem
Modern music listeners have their identities split across:
* **Local Storage:** Owned, high-quality, offline files.
* **Spotify:** Premium metadata, discovery, and curated playlists.
* **YouTube:** An infinite library of remixes, live sets, and rare tracks.

### The Solution
The purpose of **Kerlyss** is to provide a **Unified Audio Environment (UAE)**. It acts as a bridge that treats every song as a single "Entity," regardless of whether the source is a local SD card, a Spotify database, or a YouTube stream.

---

## 2. Project Roadmap: Phase 1 (MVP)

| Phase | Milestone | Key Deliverables |
| :--- | :--- | :--- |
| **01** | **The Core Engine** | Flutter setup, `audio_service` integration, background playback. |
| **02** | **Local Discovery** | Permission handling, `on_audio_query` scanning, Local ID3 parsing. |
| **03** | **The Bridge** | Spotify Metadata API integration + YouTube audio stream extraction. |
| **04** | **Persistence** | Isar NoSQL Database for offline playlists and "Hearts." |
| **05** | **Polish** | Glassmorphic UI, gapless transitions, and "Aether-style" aesthetics. |

---

## 3. Technical Project Structure (Clean Architecture)

This modular structure ensures **Kerlyss** remains "Server-Ready." You can swap local logic for a dedicated backend later without touching the UI code.

### Folder Hierarchy:
- **lib/**
    - **core/** : Global constants, themes, and network utilities.
    - **domain/** : The "Brain" (Entities, Abstract Repositories, UseCases).
    - **data/** : The "Muscle" (API implementations, Models, Repository logic).
    - **presentation/** : The "Face" (Screens, State Providers, UI Widgets).
    - **services/** : OS-Level Services (Audio Background Handler, DB Service).
    - **main.dart** : Application Entry Point.

---

## 4. Key Functional Features

### **A. Intelligent Concurrent Search**
When a user searches, Kerlyss triggers three simultaneous streams:
1. **Local Index:** Instant results from device storage.
2. **Spotify API:** Professional metadata (High-res art, Artist bio).
3. **YouTube Engine:** Locates the best audio stream to match the Spotify metadata.

### **B. Premium UX/UI**
* **Source Badging:** Visual indicators showing if a track is Local, Spotify, or YT.
* **Smart Caching:** Automatic background caching of streamed tracks to save data.
* **Gapless Audio:** Utilizing the `just_audio` engine for seamless transitions.

---

## 5. Technical Stack (2026 Recommended)

* **Framework:** Flutter (iOS, Android, Desktop).
* **State Management:** Riverpod (Reactive & Testable).
* **Audio Engine:** `just_audio` + `audio_service`.
* **Local Database:** Isar (Fast NoSQL) or Drift (SQL).
* **Network Client:** Dio (For robust API calls).

---

## 6. Future Scalability
* **Backend Integration:** The Repository Pattern allows a seamless switch to a dedicated Kerlyss Server.
* **Social Layer:** Designed to support playlist sharing via JWT-authenticated accounts in later versions.




# 🎵 Kerlyss: High-Level Project Architecture

## 1. The Directory Tree
This follows the **Layered Clean Architecture** pattern. Each layer has a specific responsibility.

```text
kerlyss/
├── android/              # Platform-specific native code
├── ios/                  # Platform-specific native code
├── assets/               # Fonts, SVG Icons, Default Album Art
└── lib/
    ├── core/             # The "Engine Room" (Global Constants & Utils)
    │   ├── constants/    # API Keys, UI Strings, Dimensions
    │   ├── theme/        # Dark/Light mode, Typography, Colors
    │   ├── network/      # HTTP Clients (Dio) & Connectivity Checkers
    │   └── error/        # Custom Failure & Exception classes
    │
    ├── domain/           # The "Business Logic" (Platform Agnostic)
    │   ├── entities/     # Pure Song, Playlist, and User objects
    │   ├── repositories/ # Abstract interfaces (The "Contract")
    │   └── usecases/     # Specific actions: PlaySong, SearchAllSources, GetLocalLibrary
    │
    ├── data/             # The "Data Provider" (Implementation)
    │   ├── datasources/  # Low-level API calls (Spotify, YT, Local Storage)
    │   ├── models/       # Data Transfer Objects (JSON Mappers)
    │   └── repositories/ # Logic to merge Local + YT + Spotify data
    │
    ├── presentation/     # The "View" (UI & State)
    │   ├── common/       # Reusable widgets (MiniPlayer, TrackTile, GlassmorphicCard)
    │   ├── state/        # State management (Riverpod/Bloc/Signals)
    │   ├── screens/      # Main UI (Home, Search, Library, PlayerView)
    │   └── animations/   # Custom Lottie/Rive music visualizers
    │
    ├── services/         # Global OS-Level Services
    │   ├── audio_handler.dart   # Background playback & Lock screen controls
    │   ├── storage_service.dart # Local SQL/NoSQL Database management
    │   └── permission_service.dart # Handling Storage/Media permissions
    │
    └── main.dart         # Entry point (Dependency Injection setup)
```

## 2. Deep Dive: Layer Responsibilities

### A. Domain Layer (The Brain)
This is the most important part of Kerlyss. It defines what the app does without knowing how.
* **Entities:** A `SongEntity` contains `id`, `title`, `artist`, `duration`, and `streamUrl`. It doesn't care if the URL is from YouTube or your future server.
* **Repositories (Abstract):** Defines `Future<List<Song>> search(String query)`.

### B. Data Layer (The Muscle)
This is where the magic of Kerlyss happens.
* **Remote Data Sources:** Logic for scraping YouTube or calling Spotify’s API.
* **Local Data Sources:** Logic for scanning the phone’s `/Music` folder.
* **Repository Implementation:** This is the "Bridge." When the UI asks for a song, this layer checks: 
    1. Do we have it locally? 
    2. If not, fetch from Spotify metadata. 
    3. Find audio on YouTube.

### C. Presentation Layer (The Face)
* **State Management:** We use a Global Audio Provider. No matter which screen the user is on, the "Now Playing" state is always synchronized.
* **Atomic Design:** Small widgets (buttons) build larger widgets (lists), which build screens.

## 3. Key Technical Components (The "Secrets")
To make Kerlyss feel like a $1B app, we need these specific implementations:

| Component | Technology | Why? |
| :--- | :--- | :--- |
| **Audio Pipeline** | `just_audio` | Supports gapless playback, caching, and custom headers for YT streams. |
| **Local Database** | **Isar Database** | Blazing fast NoSQL. Perfect for storing thousands of offline song metadata entries. |
| **Dependency Injection** | **GetIt** | Allows us to swap the "MockData" with "RealServerData" in one line of code. |
| **Background Task** | `audio_service` | Keeps Kerlyss alive when the user is on Instagram or the screen is locked. |

## 4. Why this structure?
* **Scalability:** If you hire a backend developer tomorrow, they can work entirely in `data/` and `domain/` without touching the UI.
* **Testability:** You can test the "Search" logic without even opening an emulator.
* **Independence:** Your UI is not tied to Spotify or YouTube. If YouTube changes their API, you only change one file in `datasources/`.

---
**Lead Developer Note:** I recommend starting by defining the `SongEntity` in the **Domain** layer. It is the heart of Kerlyss.