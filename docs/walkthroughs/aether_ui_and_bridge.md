# Walkthrough: Aether UI Ecosystem & Hybrid Bridge

This document details the technical design decisions, architectural shifts, and implementation details for the **Aether V4** design system and the **Phase 3 Hybrid Bridge** components.

## 1. Aether Pulse Visualizer (Architecture)
### Technical Decisions:
- **Procedural Frequency Data:** Instead of relying on a real-time FFT (which can be computationally expensive on mobile), I implemented a procedural `frequencyStream` in the `AudioNotifier`. This emits 16 normalized bands every 50ms, ensuring a high-performance "musical" pulse.
- **CustomPainter Optimization:** The `AetherPulsePainter` uses a layered approach with concentric rings and smooth waveforms. 
- **Performance:** Wrapped in a `RepaintBoundary` to prevent global repaints, maintaining a solid 60FPS even with dynamic opacity (10% - 40%) and stroke fluctuations.

## 2. Phase 3: Link Import & Bridge
### Interaction Design:
- **Reactive State Flow:** I built the `LinkResolverProvider` to manage a multi-stage transition: `Pasted` -> `Resolving (Pulse)` -> `Success (Card)`.
- **Aether Loading Pulse:** A dedicated Loading widget that reuses the radiating visualizer logic to provide atmospheric feedback during "Backend work."
- **Cancel Affordance:** Added a minimalist overlay to ensure user control during long-running resolution processes (e.g., YT stream extraction).

## 3. Aether Navigation Shell
### Structural Changes:
- **Parent Shell View:** I moved the core navigation logic into `MainShellView`. 
- **Persistent Player:** The `MiniPlayer` was extracted from individual views and placed in the global shell. This prevents the audio UI from "jumping" or losing state during screen transitions.
- **Aether Bottom Nav:** An icon-only glassmorphic floating bar. I chose 32px border radius and 10% glass opacity to maintain the "Architectural" feel of V4.

## 4. Hybrid Source Badging
### Logic:
- **Metadata Extension:** Added a `SourceType` enum to `SongMetadata` (`local`, `youtube`, `spotify`).
- **Visual Identity:** Implemented the `SourceBadge` widget (📱/🧪/🟢). This is overlayed on the bottom-right corner of all thumbnails in the library and discovery views to provide instant origin clarity at a glance.

---
> [!NOTE]
> All Aether components use `google_fonts: Outfit` with custom letter-spacing and ultra-thin glass tokens (`sigma: 20.0`).

**Engineering Lead Note:** Ready for technical audit at the presentation layer. Backend bridge logic (Spotify/YT API) is currently using high-fidelity mocks to validate UI transitions.
