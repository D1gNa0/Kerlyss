# UI/UX Handoff Specifications

## 1. Aesthetic Pillar: "Aether"
The design language for Kerlyss is derived from the "Aether" design system—focusing on depth, transparency, and motion.

### Core Tokens
*   **Backdrop:** Deep Matte Black or Ultra Dark Gray.
*   **Overlays:** 15% - 25% opacity glass containers (Sigma blur: 20.0).
*   **Accents:** Vibrancy colors derived from the active album art (Dynamic UI).
*   **Typography:** [Google Font: Outfit] or [Inter].

## 2. Widget Architecture

### Unified Player
*   **Transitions:** Shared element transitions between MiniPlayer and FullScreenPlayer.
*   **Controls:** Minimalist playback controls with haptic feedback integration.
*   **Visualizer:** Real-time waveform or particle system synced to `audio_service` stream.

### Search Interaction
*   **Concurrent Loading:** Skeleton loaders for Local, Spotify, and YouTube sections.
*   **Source Badging:** Subtle icons next to titles (📱 Local, 🧪 YT, 🟢 Spotify).

## 3. Interaction Requirements
*   **Pull-to-Refresh:** Trigger a re-scan of the local library.
*   **Swipe-to-Action:** Quick add to playlist or "Heart" from any list view.

### Aether Pulse Visualizer
*   **Component:** `AetherPulseVisualizer` (CustomPainter).
*   **Source:** Bind to the `audioProvider` stream for real-time frequency data.
*   **Aesthetic:** Glowing particles or smooth waveform with dynamic opacity (10% - 40%) based on volume.

### Aether Shell Navigation
*   **Structure:** BottomNavigationBar with 3 items: **Discover**, **Library**, **Settings**.
*   **Aesthetic:** Transparent glass blur with minimalist icons (Outlined when idle, Filled when active).
*   **Transition:** Cross-fade between tabs with a 200ms duration.

### Discovery UI
*   **Search Bar:** Centered, floating glass design.
*   **Import Bridge:** A BottomSheet containing options for [Spotify Playlist Link] and [YouTube Link].
*   **Source Badging:** Each song card must show a subtle hybrid badge for its metadata/audio source.

---
**Senior UI/UX Note:** Priority is on smoothness. Ensure all animations are at 60fps. Use `RepaintBoundary` for heavy widgets like the visualizer.
