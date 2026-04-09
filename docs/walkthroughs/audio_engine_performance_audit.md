# Walkthrough: Audio Engine Performance & Stability Audit

## 🏷️ Feature Overview
Establishment of a robust QA framework for the Kerlyss audio ecosystem, focusing on 60FPS visualizer fluidness, YouTube stream caching stability, and hybrid resolution regression stubs.

## 🛠️ Technical Decisions

### 1. Performance Profiling with Standard Timeline
- **Decision:** Use `dart:developer`'s `Timeline` class instead of custom profiling classes.
- **Rationale:** Standard Timeline events are automatically picked up by **Flutter DevTools**, allowing the engineering lead to inspect the rendering pipeline on physical hardware without additional tooling.
- **Implementation:** Added `Timeline.startSync('AetherPulse:Paint')` at the beginning of the visualizer's `paint` method to track frame times.

### 2. Concurrency Control in YoutubeAudioEngine
- **Decision:** Implement an `_activeResolutions` map to track pending asynchronous calls.
- **Rationale:** YouTube stream resolution (`YoutubeExplode`) is an expensive network operation. If multiple UI components or rapid track skips trigger simultaneous resolutions for the same ID, redundant network traffic occurs.
- **Implementation:** Used a `Future`-based locking mechanism to ensure only one resolution occurs per track ID, with simultaneous requests awaiting the same future.

### 3. Tiered Caching Strategy
- **Decision:** 5-hour TTL (Time-To-Live) for memory-cached stream URIs.
- **Rationale:** YouTube stream headers typically expire in 6 hours. A conservative 5-hour window ensures high reliability while minimizing "403 Forbidden" errors for cached links.

### 4. Regression Stubs for Hybrid Resolution
- **Decision:** Implementation of direct filesystem path stubs in `SongRepositoryImpl`.
- **Rationale:** Aligns with the Phase 2 roadmap for local media discovery (`on_audio_query`). This ensures the repository layer is "contract-ready" for the integration of local file streaming.

## 📁 Key Changes

### Presentation Layer
- **`lib/presentation/common/aether_pulse_visualizer.dart`**: Integrated Timeline hooks and optimized shader creation for the visualizer rings.

### Data Layer
- **`lib/data/datasources/remote/youtube_audio_engine.dart`**: Stabilized the tiered memory cache with concurrency locking.
- **`lib/data/repositories/song_repository_impl.dart`**: Unified the resolution interface for YouTube and prospective local sources.

### Testing Suite
- **`test/data/youtube_audio_engine_test.dart`**: Unit tests verifying the concurrency lock and TTL expiration logic.
- **`test/regression/hybrid_audio_resolution_test.dart`**: Regression tests for the unified streaming interface.

## 📈 Verification Results
- **Unit Tests:** ✅ PASS (Engine Caching & Concurrency)
- **Regression:** ✅ PASS (Hybrid Resolution Contract)
- **Fluidity:** ⌛ PENDING (Requires Physical Device Profiling - Hooks Ready)

---
**Audit Status:** `STABLE`
**Lead QA Engineer:** Antigravity (Advanced Agentic Coding)
