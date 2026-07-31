# Design Spec — Kerlyss 2.5D Dynamic Light & Glass UI System

## Goal & Overview
Redesign the Kerlyss Flutter music player and web user interface to feature a **2.5D Dynamic Light & Glass System** inspired by Vercel's lightning stroke glows, Raycast's warm crimson glassmorphism, and Family.co's technical luxury cards. 

The system features:
1. **2.5D Ambient Background Mesh/Rays**: Soft desaturated background radial light rays behind translucent glass cards (`BackdropFilter` blur 15px).
2. **Vercel-Style Glowing Edge Beam**: Clicked/active buttons, mode chips, and focused search inputs feature an animated 1px glowing edge stroke (`#F43F5E`).
3. **Cursor-Following Radial Light**: Desktop/web mouse movement creates a desaturated ambient radial light glow (`#F43F5E` at 8% opacity) that highlights card borders.
4. **Unified Color Palette**: Single active accent color (**Warm Crimson Coral `#F43F5E`**) used across all active controls, eliminating mismatched button colors.

---

## Visual Design Tokens

### Color Palette & Surfaces
- **Primary Background**: Dark Charcoal Obsidian (`AetherColors.deepMatteBlack` `#0A0A0E`)
- **Card & Surface Fill**: Translucent Glass Slate (`AetherColors.ultraDarkGray` `#14141C`) with 10% white alpha
- **Hairline Borders**: `AetherColors.glassBorder` (`Colors.white.withValues(alpha: 0.10)`)
- **Unified Primary Accent**: Warm Crimson Coral (`AetherColors.primaryAccent` `#F43F5E`)
- **Unified Secondary Accent**: Crimson Glow Highlight (`AetherColors.secondaryAccent` `#FB7185`)
- **Text & Typography**:
  - Primary Text: Cream Off-White (`#F9FAFB`)
  - Secondary Text: Soft Slate Gray (`#9CA3AF`)
  - Font Family: Google Fonts `Outfit`

---

## Component Specifications

### 1. Cursor-Following Light Canvas (`AmbientLightCanvas`)
- Wraps top-level scaffold views on Desktop & Web.
- Tracks mouse pointer offset (`PointerHoverEvent`).
- Renders a soft 150px radial gradient glow at 8% opacity centered at mouse position.

### 2. Vercel-Style Glowing Edge Follower (`GlowEdgeContainer`)
- Wraps interactive buttons, focused search bar, and active playlist chips.
- Renders a 1px gradient stroke border using `SweepGradient` or `LinearGradient` in `AetherColors.primaryAccent` (`#F43F5E`) and `AetherColors.secondaryAccent` (`#FB7185`).

### 3. Floating Glass Dock Mini-Player & Navigation (`MiniPlayer`)
- Positioned floating pill container with 20px rounded corners.
- Background: `Color(0xFF0A0A0E).withValues(alpha: 0.85)` with 15px backdrop blur.
- Top Progress Line: 2px Warm Crimson progress bar (`#F43F5E`).
- Play/Pause Button: Velvet Crimson circular container with 48x48px minimum touch target.

---

## Verification Plan
1. Run `flutter test` to ensure all unit and widget tests pass.
2. Verify all interactive controls use unified Crimson Coral (`#F43F5E`) accents.
