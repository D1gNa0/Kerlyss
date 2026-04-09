# Backend & Data Architecture Specifications

## 1. Domain Entities

### `SongEntity`
The primary data object in the system.
```dart
class SongEntity {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? albumArtUrl;
  final Duration duration;
  final String sourceUrl; // YouTube Stream URI or Local File Path
  final AudioSourceType sourceType; // Enum: local, spotify, youtube
}
```

## 2. External Integrations

### Spotify Metadata API
*   **Purpose:** Enriched metadata retrieval.
*   **Workflow:** Search query -> Spotify Metadata -> Store ID for cross-referencing.
*   **Deliverables:** Artist bio, High-res artwork (1024x1024), Genre tags.

### YouTube Audio Engine
*   **Purpose:** On-demand audio streaming.
*   **Workflow:** `SongEntity` metadata match -> Search YouTube -> Extract Opus/AAC stream -> Pass to `just_audio`.
*   **Optimization:** Implement stream caching to `getTemporaryDirectory()` for repeat plays.

## 3. Persistence Layer (Isar DB)

### Schemas
*   **LibraryCollection:** Stores indexed local files.
*   **FavoriteCollection:** Stores user "hearts" (Mixed Local/Remote).
*   **PlaylistCollection:** Array of `SongEntity` IDs.

### YouTube Audio Engine
*   **Provider:** Integrate `youtube_explode_dart` or a similar stream-extraction utility.
*   **Extraction Requirement:** Resolve `sourceUrl` from a YouTube ID/URL into a direct Opus/AAC stream URI.
*   **Caching Policy:** Implement a tiered caching system—Metadata (Isar) | Stream Headers (Memory).

### Search Aggregator (Discovery Engine)
*   **Logic:** `SearchAggregator` performs sequential requests to Spotify (Public Metadata) and YouTube (Audio).
*   **Fuzzy Matching:** Implement a weighting system—Title (1.0) | Artist (0.8). If score > 0.85, merge into a single `SongEntity`.
*   **Enrichment:** Prefer Spotify artwork (640px) as the primary visual asset.

---
**Lead Backend Dev Note:** No hardcoded API keys. Use environment variables defined in `.env`. Focus on performance—search requests must be parallelized where possible.
