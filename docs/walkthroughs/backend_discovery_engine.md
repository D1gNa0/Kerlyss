# Technical Walkthrough: Backend Discovery & Streaming Architecture

This document outlines the technical implementation, architectural decisions, and data flows for the core backend engine of Project Kerlyss.

## 1. Architectural Overview

The engine follows **Strict Clean Architecture** principles to ensure platform independence and testability.

-   **Domain Layer**: Defines the core `SongEntity` and `SongRepository` interfaces. It remains agnostic of how data is fetched or streams are extracted.
-   **Data Layer**: Contains the implementation of data sources (Isar, YouTube, Spotify Public).
-   **Infrastructure**: Integration of `Riverpod` for dependency injection and `youtube_explode_dart` for stream resolution.

## 2. YouTube Audio Engine

The "Engine" of the project handles direct stream resolution and extraction.

### Tiered Caching Policy
-   **Level 1: Metadata (Isar)**: Persistent storage of video IDs, titles, and thumbnails.
-   **Level 2: Stream Headers (Memory)**: Resolving a streaming URI is network-expensive. We implement a memory cache in `YoutubeAudioEngine` with a 5-hour TTL (matching YouTube's ~6-hour URI expiration).
-   **Concurrency Control**: A locking mechanism prevents multiple simultaneous resolution requests for the same ID, reducing network overhead.

## 3. Spotify Public Integration (No-API Protocol)

To minimize reliance on developer keys and official APIs, we utilize public endpoints.

-   **OEmbed Integration**: We resolve Spotify URLs (`open.spotify.com/track/...`) using the `/oembed` endpoint to harvest high-resolution artwork and metadata.
-   **Public Search**: Implemented a foundation for parsing Spotify's public search results to obtain high-quality metadata for mirroring.

## 4. Search Aggregator (Discovery Engine)

The Aggregator merges the rich descriptive data of Spotify with the streaming power of YouTube.

### Parallel Search
Search requests are executed in parallel across platforms using `Future.wait` to maintain a low-latency UI response.

### Fuzzy Matching Logic
We use a weighted similarity algorithm to deduplicate results:
-   **Title Similarity**: Weight 1.0
-   **Artist Similarity**: Weight 0.8
-   **Threshold**: 0.85

Results above the threshold are merged into a single `SongEntity` with `AudioSourceType.spotify`, effectively "mirroring" the track.

## 5. Dependency Injection

We use Riverpod for a reactive and maintainable DI tree:
-   `isarDatabaseServiceProvider`: Scoped with `overrideWithValue` in `main.dart` after async initialization.
-   `youtubeServiceProvider`: Includes `onDispose` hooks to ensure clean resource release of the `YoutubeExplode` client.
-   `searchAggregatorProvider`: Orchestrates the interaction between data sources.

---

**Documented by:** Senior Backend Developer (AI)
**Date:** 2026-04-10
**Status:** Implementation Complete / Seeking Audit.
