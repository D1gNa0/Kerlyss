# QA Audit & Testing Protocol

## 1. Unit Test Coverage
*   [ ] **Domain:** Ensure UseCases return correct Failures on empty repository responses.
*   [ ] **Data:** Validate `SongModel` from JSON mappers (Spotify/YT).

## 2. Integration & Smoke Tests

### Audio Engine
*   [x] **Background Playback:** Test if audio continues when the app is minimized. (PASS)
*   [ ] **Notification Controls:** Verify Play/Pause/Skip from the OS notification bar.
*   [ ] **Gapless Transition:** Audit the time between two sequential tracks for audible gaps.
*   [x] **YouTube Streaming:** Verify high-res audio extraction and URI resolution. (PASS)

### Persistence
*   [ ] **Offline Mode:** Verify that "Hearted" local tracks play without internet.
*   [ ] **Isar Corruption:** Test app behavior if the Isar database file is deleted externally.

## 3. Bug Tracker (Internal)
| ID | Priority | Feature | Description | Status |
| :--- | :--- | :--- | :--- | :--- |
| CORE-001 | P0 | Bootstrap | Initial Folder Setup Audit | ✅ PASS |
| QA-001 | P0 | Environment | Missing `test/` directory and framework config | ✅ FIXED |
| YT-001 | P0 | Audio Engine | YouTube Stream Extraction (Manual Audit) | ✅ PASS |
| UI-001 | P1 | Visualizer | Aether Pulse 60FPS Verification | ✅ PASS (Audit Hooks Ready) |
| YT-002 | P0 | Audio Engine | YouTube Engine Concurrency & Caching | ✅ STABLE |

---
**Lead QA Note:** 
*   **Performance:** All profiling must use **Standard Timeline events** (`dart:developer`) for seamless integration with Flutter DevTools.
*   **Regression Stubs:** Utilize **Direct Filesystem Paths** for initial local audio stubs to mirror the production schema of `on_audio_query`.
*   **Device Audit:** All tests should be performed on both an Android Emulator and a physical device to verify hardware-accelerated blur performance.
