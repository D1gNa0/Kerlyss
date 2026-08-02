# 3-Tier Color & Vercel Hover Light System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Vercel hover background light buttons (`VercelHoverButton`) and refactor Kerlyss theme to a **3-Tiered Color System**: Electric Indigo (`#6366F1`) for primary actions, Emerald Green (`#10B981`) for downloads, and Crimson Red (`#E11D48`) for caution/destructive actions. Remove mouse-following canvas overlay from app.

**Architecture:** `AetherColors` 3-tiered palette + `VercelHoverButton` widget integrated across `AetherTheme`, `MiniPlayer`, `DiscoverySearchBar`, and `PlaylistsView`.

---

### Task 1: Refactor AetherColors 3-Tier Palette & Build VercelHoverButton

**Files:**
- Modify: `lib/presentation/theme/aether_colors.dart`
- Modify: `lib/presentation/theme/aether_theme.dart`
- Modify: `lib/main.dart` (remove AmbientLightCanvas)
- Create: `lib/presentation/common/vercel_hover_button.dart`
- Create: `test/presentation/vercel_hover_button_test.dart`

- [ ] **Step 1: Write test for VercelHoverButton**
- [ ] **Step 2: Update AetherColors (Indigo #6366F1, Emerald #10B981, Crimson #E11D48)**
- [ ] **Step 3: Build `vercel_hover_button.dart` with background backlight hover effect**
- [ ] **Step 4: Verify test passes (`flutter test test/presentation/vercel_hover_button_test.dart`)**
- [ ] **Step 5: Commit changes**

---

### Task 2: Refactor MiniPlayer & DiscoverySearchBar to VercelHoverButton & 3-Tier Colors

**Files:**
- Modify: `lib/presentation/common/mini_player.dart`
- Modify: `lib/presentation/screens/discovery_components/discovery_search_bar.dart`

- [ ] **Step 1: Apply Electric Indigo to Play/Pause, Emerald to Download, Crimson to Unlike**
- [ ] **Step 2: Wrap MiniPlayer and DiscoverySearchBar buttons in VercelHoverButton**
- [ ] **Step 3: Verify tests pass (`flutter test`)**
- [ ] **Step 4: Commit changes**

---

### Task 3: Refactor PlaylistsView & PlaylistDetailView Dialog Buttons & Verify Suite

**Files:**
- Modify: `lib/presentation/screens/playlists_view.dart`
- Modify: `lib/presentation/screens/playlist_detail_view.dart`

- [ ] **Step 1: Apply Emerald to "Download All Tracks", Crimson to "Stop Downloading" / "Delete Playlist", Indigo to "Real-Time Sync"**
- [ ] **Step 2: Run full test suite (`flutter test`)**
- [ ] **Step 3: Commit changes**
