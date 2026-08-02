# Design Spec — Kerlyss 3-Tier Color & Vercel Hover Light System

## Goal & Overview
Redesign Kerlyss buttons and cards using a **3-Tiered Color System (Color Theory)** and **Vercel Hover Background Light Effects** (`VercelHoverButton`). Mouse-following canvas light is removed from the Flutter app (kept for website).

---

## 3-Tiered Color System

1. **Tier 1: Caution / Destructive Red (`AetherColors.error` / `Color(0xFFE11D48)`)**
   - Used sparingly for critical/caution actions: Delete Playlist, Remove Downloaded Files, Stop Bulk Download, Unlike.

2. **Tier 2: Download / Sync Emerald Green (`AetherColors.success` / `Color(0xFF10B981)`)**
   - Used for download actions, downloaded offline badges, and sync success indicators.

3. **Tier 3: Neutral Primary Electric Indigo (`AetherColors.primaryAccent` / `Color(0xFF6366F1)`)**
   - Used for core primary actions: Play/Pause, Search mode toggles, queue toggle, navigation, and general buttons.

---

## Vercel Hover Background Light Effect (`VercelHoverButton`)
- On hover/focus, buttons and list items render an internal background light backlight (`RadialGradient` centered on button background) that illuminates from behind the button fill, exactly like Vercel.com.
- Hairline 1px border highlights smoothly on hover (`Colors.white.withValues(alpha: 0.2)`).

---

## Visual Design Tokens

- **Canvas Background**: Dark Obsidian (`#0A0A0E`)
- **Card Surfaces**: Dark Charcoal Slate (`#14141C`) with 10% white hairline borders (`#1AFFFFFF`)
- **Tier 1 Caution**: Crimson (`#E11D48`)
- **Tier 2 Download**: Emerald (`#10B981`)
- **Tier 3 Primary**: Electric Indigo (`#6366F1`)
- **Text**: Cream Off-White (`#F9FAFB`) & Soft Slate Gray (`#9CA3AF`)

---

## Verification Plan
1. Run `flutter test` to verify all 24+ tests pass.
2. Verify all buttons implement Vercel hover background light and respect 3-tiered color roles.
