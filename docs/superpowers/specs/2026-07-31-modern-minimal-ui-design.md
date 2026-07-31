# Design Spec — Kerlyss Modern Minimalist UI Redesign

## Goal & Overview
Redesign the Kerlyss Flutter music player user interface to be sleek, modern, minimal, and crafted with a human touch (inspired by Linear and Apple dark minimalist design principles). The interface avoids generic AI-template tropes by using refined dark matte surfaces, subtle 1px borders, crisp typography, and floating glass components.

---

## Visual Design Tokens

### Color Palette & Surfaces
- **Primary Background**: `AetherColors.deepMatteBlack` (`#0C0C0C`)
- **Card & Surface Fill**: `AetherColors.ultraDarkGray` (`#121212`) & `Colors.white.withValues(alpha: 0.03)`
- **Borders & Dividers**: `AetherColors.glassBorder` (`Colors.white.withValues(alpha: 0.08)`) & `Colors.white10`
- **Accent Colors**:
  - Primary Accent: Lucid Purple (`#A855F7`)
  - Accent Cyan: Vibrant Cyan (`#22D3EE`)
  - Accent Amber: Real-Time Sync Amber (`#F59E0B`)
  - Success Green: Offline Downloaded (`#34D399`)

### Typography System
- **Font Family**: Google Fonts `Outfit`
- **Display Titles**: Bold 14px uppercase, 4.0 letter-spacing (`displayMedium`)
- **Track Titles**: 14px SemiBold (`titleLarge`)
- **Subtitles & Metadata**: 11px Medium, 1.0 letter-spacing (`bodyMedium`) in `Colors.white38` / `textSecondary`

---

## Component Specifications

### 1. Floating Glass Dock Mini-Player & Bottom Navigation
- **Structure**: Floating pill-shaped container positioned at the bottom of the viewport with 16px side margins and 12px bottom padding.
- **Visual Style**:
  - `BorderRadius.circular(20)`
  - Background: `Colors.black.withValues(alpha: 0.75)` with `BackdropFilter` (blur 15x15)
  - 1px hairline border: `Colors.white.withValues(alpha: 0.12)`
- **Elements**:
  - Left: 40x40px album thumbnail with rounded corners.
  - Center: Track title & artist with smooth scrolling marqee/overflow.
  - Right: Play/Pause toggle (48x48px target), skip track icon, volume popover slider, and playlist queue toggle.
  - Top Progress Line: Thin 2px cyan progress line along the top border of the dock.

### 2. Discovery View & Search Bar
- **SearchBar**: 60px height container with dynamic cyan/purple gradient focus border when focused (`focusNode.hasFocus`).
- **Touch Targets**: 48x48px minimum touch targets for mode toggle chip (`[🎵 Songs]` / `[🟢 Spotify Link]`) and clear (`X`) button.
- **Search Results**: Clean list tiles with 12px vertical spacing, album artwork, track duration, and single-tap playback / add-to-playlist actions.

### 3. Playlists View & Playlist Detail View
- **Playlist Cards**: Clean cards with 16px border radius, green `DOWNLOADED` status badge when all tracks are stored locally.
- **Header Actions**:
  - **`⚡` Sync & Download Settings**: Always visible on all playlists.
  - **Delete Playlist**: Confirmation dialog before removal.
  - *No redundant "Download All" icon buttons on cards or app bars.*
- **Sync & Download Settings Modal**:
  - Custom insets: `insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24)`, `contentPadding: EdgeInsets.fromLTRB(20, 16, 20, 16)`.
  - Standing Toggles: **`⚡ Real-Time Sync`** and **`🔄 Auto-Download New Songs`**.
  - Context-Aware Action Button:
    - **`DOWNLOAD ALL TRACKS NOW`** (`OutlinedButton` cyan) when tracks are missing.
    - **`STOP DOWNLOADING`** (`OutlinedButton` amber) when bulk download is active.
    - **`REMOVE DOWNLOADED FILES`** (`OutlinedButton` red) when all tracks are downloaded offline.

---

## State Management & Services
- **`AudioNotifier` (`audioProvider`)**: Controls current track, playback state, and local file playback resolution.
- **`DownloadStateNotifier` (`downloadStateProvider`)**: Tracks active downloads, progress percentages, and bulk status.
- **`TrackDownloadService` (`trackDownloadServiceProvider`)**: Manages track downloads, candidate video fallbacks (`_getManifestWithFallback`), and `cancelBulkDownload()`.
- **`PlaylistNotifier` (`playlistProvider`)**: Handles Isar DB persistence for playlists and real-time sync flags (`isRealtimeSynced`, `autoDownloadNewTracks`).

---

## Verification Plan
1. **Automated Tests**: Run `flutter test` to ensure all 20 existing unit, widget, and state tests pass.
2. **Visual & Touch Target Audit**: Verify that all buttons meet minimum 48x48px touch target constraints and no text or switch widgets overflow dialog boundaries.
