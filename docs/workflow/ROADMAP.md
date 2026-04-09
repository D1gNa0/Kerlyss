# Project Kerlyss: Product Roadmap

## 🎯 Vision
Kerlyss is a high-performance, unified audio ecosystem designed to bridge Local Storage, Spotify Metadata, and YouTube Streaming into a single, seamless experience.

## 🛤 Milestones

### Phase 1: The Core Engine (Q2 2026)
*   [x] **Clean Architecture Foundation:** Initialize directory structure and core utilities. (DONE)
*   [ ] **Domain Layer Definition:** Finalize `SongEntity`, `PlaylistEntity`, and Repository interfaces.
*   [ ] **Audio Service Integration:** Implement `just_audio` and `audio_service` for background playback.
*   [ ] **Dependency Injection:** Setup `GetIt` or Riverpod-based DI.

### Phase 2: Local Discovery & Persistence (Q2 2026)
*   [ ] **Permission Handling:** Implement platform-specific permission requests for media/storage.
*   [ ] **Local Scanning:** Integrate `on_audio_query` for device indexing.
*   [ ] **Isar Database Setup:** Initialize NoSQL storage for favorites, local metadata, and playlists.

### Phase 3: The Hybrid Bridge (Q3 2026)
*   [x] **Spotify Metadata Integration:** Fetch high-res album art and artist details via Spotify API. (STUBBED/PASS)
*   [x] **YouTube Streaming Logic:** Implement YT audio extraction and stream caching. (DONE)
*   [x] **Search Aggregator:** Unified search results from Local, Spotify, and YouTube. (DONE)

### Phase 4: Aether Aesthetics & Polish (Q3 2026)
*   [ ] **Glassmorphic UI:** Implement custom themes and blur effects.
*   [ ] **Gapless Playback:** Optimize `just_audio` for seamless track transitions.
*   [ ] **Performance Audit:** 60FPS UI rendering and minimized memory footprint for audio buffering.

---
**Lead Product Note:** This roadmap is a living document. Engineering leads should update milestone status upon completion of corresponding technical specifications.
