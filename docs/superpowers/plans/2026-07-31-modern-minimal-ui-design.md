# Modern & Minimal UI Redesign (Burgundy & Khaki Theme) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the Kerlyss user interface to a sleek, modern, dark minimalist aesthetic (inspired by Linear and Apple) with a floating glass dock mini-player, clean 1px hairline borders, refined Google Fonts `Outfit` typography, and a luxury Burgundy (`#8B1E3F`) & Khaki (`#C3B091`) color palette on a deep charcoal black canvas (`#0A090A`).

**Architecture:** The redesign builds on existing Riverpod state management (`audioProvider`, `downloadStateProvider`, `playlistProvider`, `trackDownloadServiceProvider`) while replacing heavy container backgrounds and ad-hoc layouts with a central theme design system (`AetherColors` and `AetherTheme`).

**Architecture Diagram:**

```mermaid
graph TD
    subgraph "Theme System"
        A[AetherColors (Burgundy & Khaki)] --> B[AetherTheme]
    end

    subgraph "Presentation Layer"
        B --> C[Floating Glass MiniPlayer]
        B --> D[DiscoverySearchBar]
        B --> E[PlaylistsView & PlaylistDetailView]
    end

    subgraph "State & Services"
        F[audioProvider] --> C
        G[downloadStateProvider] --> E
        H[trackDownloadServiceProvider] --> E
    end
```

**Tech Stack:** Flutter 3.x, Riverpod 2.6.1, Google Fonts (`Outfit`), Isar DB.

## Global Constraints
- **Primary Background**: `AetherColors.deepMatteBlack` (`Color(0xFF0A090A)`)
- **Primary Accent**: Velvet Burgundy (`Color(0xFF8B1E3F)`)
- **Secondary Accent**: Warm Khaki (`Color(0xFFC3B091)`)
- **Primary Text**: Cream White (`Color(0xFFF5F2EB)`)
- **Secondary Text**: Soft Khaki Gray (`Color(0xFF9E978E)`)
- **Card Borders**: `AetherColors.glassBorder` (`Color(0x14FFFFFF)`) 1px border side
- **Minimum Touch Target**: 48x48px for interactive icons and chips
- **Dialog Layout Insets**: `insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24)`, `contentPadding: EdgeInsets.fromLTRB(20, 16, 20, 16)`

---

### Task 1: Refactor Design System Tokens & Typography (Burgundy & Khaki)

**Files:**
- Modify: `lib/presentation/theme/aether_colors.dart`
- Modify: `lib/presentation/theme/aether_theme.dart`
- Create: `test/presentation/theme_tokens_test.dart`

**Interfaces:**
- Consumes: Google Fonts `Outfit` text styles
- Produces: `AetherColors` static constants & `AetherTheme.darkTheme`

- [ ] **Step 1: Write failing theme tokens test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/presentation/theme/aether_colors.dart';
import 'package:kerlyss/presentation/theme/aether_theme.dart';

void main() {
  test('AetherColors defines deep charcoal black backdrop, burgundy, khaki, and cream text', () {
    expect(AetherColors.deepMatteBlack.value, equals(0xFF0A090A));
    expect(AetherColors.primaryAccent.value, equals(0xFF8B1E3F)); // Velvet Burgundy
    expect(AetherColors.secondaryAccent.value, equals(0xFFC3B091)); // Warm Khaki
    expect(AetherColors.textPrimary.value, equals(0xFFF5F2EB)); // Cream White
  });

  test('AetherTheme builds darkTheme with Outfit textTheme and deepMatteBlack scaffold', () {
    final theme = AetherTheme.darkTheme;
    expect(theme.scaffoldBackgroundColor, equals(AetherColors.deepMatteBlack));
    expect(theme.useMaterial3, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/theme_tokens_test.dart`

- [ ] **Step 3: Update `aether_colors.dart` and `aether_theme.dart`**

Set `AetherColors.deepMatteBlack = Color(0xFF0A090A)`, `ultraDarkGray = Color(0xFF131114)`, `primaryAccent = Color(0xFF8B1E3F)`, `secondaryAccent = Color(0xFFC3B091)`, `accentCyan = Color(0xFFD4C5A9)`, `textPrimary = Color(0xFFF5F2EB)`, `textSecondary = Color(0xFF9E978E)`.

- [ ] **Step 4: Verify test passes**

Run: `flutter test test/presentation/theme_tokens_test.dart`

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/theme/ test/presentation/theme_tokens_test.dart
git commit -m "style: update AetherColors and AetherTheme to Burgundy & Khaki palette"
```

---

### Task 2: Implement Floating Glass Dock Mini-Player Component

**Files:**
- Modify: `lib/presentation/common/mini_player.dart`
- Create: `test/presentation/floating_mini_player_test.dart`

**Interfaces:**
- Consumes: `audioProvider`, `downloadStateProvider`
- Produces: Floating glass dock widget with 20px rounded corners, top khaki progress line, and burgundy play button

- [ ] **Step 1: Write failing floating mini player widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerlyss/presentation/common/mini_player.dart';

void main() {
  testWidgets('MiniPlayer renders floating pill container with rounded corners', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MiniPlayer(),
          ),
        ),
      ),
    );

    expect(find.byType(MiniPlayer), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify initial state**

Run: `flutter test test/presentation/floating_mini_player_test.dart`

- [ ] **Step 3: Refactor `MiniPlayer` layout in `lib/presentation/common/mini_player.dart`**

Wrap `MiniPlayer` in `Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12))` with `ClipRRect(borderRadius: BorderRadius.circular(20))` and `BackdropFilter(filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15))`. Add top hairline progress bar in `AetherColors.secondaryAccent`.

- [ ] **Step 4: Run test to verify pass**

Run: `flutter test test/presentation/floating_mini_player_test.dart`

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/common/mini_player.dart test/presentation/floating_mini_player_test.dart
git commit -m "style: implement Floating Glass Dock MiniPlayer with Burgundy accent"
```

---

### Task 3: Apply Minimalist Burgundy & Khaki Card Layout & Verify Suite

**Files:**
- Modify: `lib/presentation/screens/playlists_view.dart`
- Modify: `lib/presentation/screens/playlist_detail_view.dart`

**Interfaces:**
- Consumes: `playlistProvider`, `downloadStateProvider`, `trackDownloadServiceProvider`
- Produces: Minimalist playlist tiles with green offline badges, khaki highlights, and clean dialog insets

- [ ] **Step 1: Run full test suite to ensure clean baseline**

Run: `flutter test`

- [ ] **Step 2: Refactor `_PlaylistTile` and dialogs in `playlists_view.dart` and `playlist_detail_view.dart`**

Apply 16px border radius, 1px glass border, khaki highlights, cream text, green offline indicator badges, and 48x48px touch targets.

- [ ] **Step 3: Run full test suite to verify all 20+ tests pass**

Run: `flutter test`

- [ ] **Step 4: Commit changes**

```bash
git add lib/presentation/screens/playlists_view.dart lib/presentation/screens/playlist_detail_view.dart
git commit -m "style: apply sleek dark minimalist Burgundy & Khaki styling to PlaylistsView and PlaylistDetailView"
```
