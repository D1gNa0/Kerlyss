# Kerlyss Codebase Health & Technical Debt Audit Report

## 1. Executive Summary
The Kerlyss application codebase demonstrates a clear intent towards a structured, modular architecture utilizing Flutter, Riverpod, and Clean Architecture principles. It successfully segregates concerns into Domain, Data, and Presentation layers, which provides a solid foundation for future scalability. However, as the application is currently in development, there are noticeable architectural weaknesses, incomplete implementations, and areas that require attention to improve long-term maintainability and stability. The most pressing concerns revolve around security practices related to dependency/environment management and the coupling of business logic within certain UI views.

## 2. Critical Findings

### 2.1 Security & Environment Configuration
*   **Missing Hardening for Local Server:** The `YoutubeProxyServer` runs a local HTTP proxy server `HttpServer.bind(InternetAddress.loopbackIPv4, 0)`. While bound to localhost, care should be taken to ensure it cannot be externally exploited or manipulated if another application gains access to the same local loopback.
*   **In-Memory Secrets Handling:** The `.env` template indicates that `JAMENDO_CLIENT_ID` is used, and there's a reliance on `flutter_dotenv` for loading these keys. While acceptable for early development, a more robust and secure strategy for managing API keys (like obfuscation or moving calls to a backend server) will be required for production to prevent reverse-engineering of secrets from the client app.

### 2.2 Architectural & Code Quality Issues
*   **"Spaghetti Code" / UI Logic Coupling:** `lib/presentation/screens/discovery_view.dart` is a very large file (over 700 lines) that heavily mixes UI definitions with complex local state management, download tracking logic (`_downloadingTrackIds`, `_downloadProgress`), and direct interaction with services. This violates the separation of concerns and reduces maintainability.
*   **Inconsistent Error Handling:** Network layers (e.g., `SpotifyPublicService`, `SearchAggregator`) use generic `throw Exception(...)` rather than defined domain-specific exception classes or Either/Result types (like `fpdart` or `dartz`). This makes it difficult for the presentation layer to distinguish between network failures, missing data, or authentication errors, leading to potentially poor user experiences.
*   **Heavy State Providers:** `lib/presentation/state/audio_provider.dart` handles the `just_audio` lifecycle, proxy initialization, and metadata mapping. It is doing too much. The actual audio playing logic should ideally be abstracted behind an interface in a service/repository, and the provider should only manage the reactive state, not the implementation details of the audio pipeline.
*   **Type Safety / `dynamic` Usage:** There is significant use of `Map<String, dynamic>` and `dynamic` in `SearchAggregator`, `SpotifyPublicService`, and `JamendoService` when handling JSON responses. This circumvents Dart's strong typing and is a major source of potential runtime crashes. Responses should be parsed into dedicated Model classes immediately.

## 3. Technical Debt Inventory

### 3.1 Incomplete Implementations & Placeholders
*   **Spotify Public Service (`lib/data/datasources/remote/spotify_public_service.dart`):** The `searchTracks` method contains a comment indicating that parsing the HTML response is "beyond a single script" and currently returns an empty placeholder list `[]`. This is a critical incomplete feature.
*   **Link Resolver Provider (`lib/presentation/state/link_resolver_provider.dart`):** The `resolveLink` method contains mocked logic: `// Mocking the "Hybrid Bridge" resolution logic for Phase 3`. It currently returns hardcoded dummy data (`resolvedSong: mockResolvedSong`).
*   **Placeholder UI Elements:** Several views (e.g., `home_view.dart`, `discovery_view.dart`, `playlist_detail_view.dart`) use hardcoded placeholder image URLs (`https://picsum.photos/seed/placeholder/200/200`) instead of proper fallback assets when `albumArtUrl` is null.
*   **Missing Features / TODOs:** `full_player_view.dart` contains unaddressed comments (`TODO`) regarding duration and slider value calculations.

### 3.2 Redundancies & Code Smells
*   **Overly Complex Caching:** `YoutubeAudioEngine` implements a custom in-memory caching mechanism (`_memoryCache`). While functional, maintaining custom caching logic can introduce bugs. Leveraging standard caching libraries or `dio_http_cache` might be more robust.
*   **Linting Warnings:** The codebase has a very high number of static analysis warnings (e.g., 1174 `undefined_identifier`, 526 `undefined_method`). This suggests that either the project dependencies are out of sync, code generation (`build_runner`) hasn't been run properly, or there is substantial broken code that needs immediate fixing before further development.
*   **Unnecessary Widget Rebuilds:** The use of `setState` in complex views like `discovery_view.dart` alongside Riverpod indicates a clash of state management strategies. Local UI state should ideally be managed via `StateProvider` or hooks to prevent massive widget tree rebuilds.

## 4. Strategic Recommendations

1.  **Refactor `DiscoveryView`:** Break down `discovery_view.dart` into smaller, reusable widget components (e.g., `DiscoverySearchBar`, `DiscoveryResultList`, `DownloadProgressOverlay`). Move the download management logic into a dedicated Riverpod `StateNotifier` or `AsyncNotifier`.
2.  **Fix Static Analysis Errors:** Immediately run `flutter pub get` and `dart run build_runner build -d` to resolve the massive amount of analyzer errors. A clean build is essential before adding new features.
3.  **Implement Robust JSON Parsing:** Replace all `Map<String, dynamic>` usage in API services with proper JSON serialization using `json_serializable` or `freezed`.
4.  **Abstract Audio Logic:** Decouple `AudioNotifier` from `just_audio`. Create an `AudioService` interface and inject it into the provider. This will make testing easier and allow swapping the audio engine in the future if needed.
5.  **Address Incomplete Features:** Prioritize completing the `SpotifyPublicService` search logic and the `LinkResolverNotifier` logic, as these are core features defined in the project's vision.
6.  **Standardize Error Handling:** Introduce custom failure classes (e.g., `NetworkFailure`, `CacheFailure`, `ParsingFailure`) and update the repository layer to return typed results (e.g., using the `fpdart` package's `Either` type) so the UI can react appropriately to specific error conditions.
