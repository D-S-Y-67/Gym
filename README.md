# Forge

Premium iOS fitness app. Native Swift 6 / SwiftUI. Deployment target iOS 17 with full Liquid Glass treatment on iOS 26.

## Setup (macOS)

Requires Xcode 26+.

```bash
brew install xcodegen
xcodegen generate
open Forge.xcodeproj
```

The Xcode project is generated from `project.yml` and is git-ignored. Re-run `xcodegen generate` after pulling changes that touch source files or the manifest.

## PR 1 — scope

This commit delivers project scaffolding and design-system primitives only. Per the spec's verification gate, the design system must be visually verified on **both** an iOS 26 simulator (Liquid Glass) and an iOS 17 simulator (materials fallback) before any feature work proceeds.

### Verification checklist

1. Run on **iOS 26 simulator** — `PreviewGallery` shows native Liquid Glass on cards, buttons, and the surrounding container.
2. Run on **iOS 17.5 simulator** — same gallery renders with `.regularMaterial` + 1pt shadow. Layout, spacing, and typography are identical to the iOS 26 build.
3. Toggle Dark Mode in both simulators — full parity.
4. Crank Dynamic Type to Accessibility XL — text scales cleanly through every primitive.
5. Tap the accent picker — selection persists across relaunches via `@AppStorage`.
6. VoiceOver pass — every interactive primitive announces a label.

If both simulators look right, the design system is locked and feature work can begin (PR 2: workout logging end-to-end).

## Architecture

```
Forge/
├── App/                 ForgeApp, RootView
├── DesignSystem/        Single source of truth for surfaces, type, color, haptics
├── Features/            One subfolder per feature (added per-PR)
├── Models/              SwiftData @Model types
├── Services/            QwenService, KeychainService, etc. (added in later PRs)
└── Resources/           Assets.xcassets
```

### Design system invariants

- **`PlatformCapabilities` is the only place `#available(iOS 26, *)` is allowed.** Everywhere else uses wrapper modifiers that branch internally.
- **No gradients.** Solid fills only — system colors, system materials, or native glass on iOS 26.
- **No third-party UI libraries.** SwiftUI only.
- **No hardcoded hex colors.** System colors and accents only.
- **Spring animations only.** No linear easing.
- **Haptics on every meaningful action.** `Haptics` static helpers for closures; `.sensoryFeedback(_:trigger:)` for state-driven views.
- **Dynamic Type, Dark Mode parity, VoiceOver labels** are non-negotiable.

## License

CC0 1.0 Universal — see `LICENSE`.
