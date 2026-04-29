# Editor cleanup — UI constants, strings, settings persistence

Scope: pure refactor (Part A) + introduce settings-via-BlobStore plumbing (Part B). Two commits, in order.

## Checklist

### Part A — Constants and strings extraction (pure refactor, no behavior change)
- [ ] Create `LiquidMetal2D-ParticleEditor/Theme/UIConstants.swift`
- [ ] Create `LiquidMetal2D-ParticleEditor/Strings/EditorStrings.swift`
- [ ] Update `Views/ContentView.swift` to read every layout/animation/icon literal from `UIConstants`
- [ ] Update `Views/ControlPanel.swift` similarly + emit label string via `EditorStrings`
- [ ] Verify clean build, run on iPad simulator — visual parity with current state
- [ ] Commit: `refactor: extract UI constants and strings`

### Part B — Settings model + BlobStore persistence
- [ ] Create `Models/Settings.swift` — `Codable` struct holding the slider ranges, with default values
- [ ] Update `Models/EditorState.swift` to expose `var settings: Settings`
- [ ] Update `Scene/ParticleEditorVC.swift` to construct a `CodableBlobStore<Settings>` over a `FileBlobStore(subdirectory: "settings")`, then load existing settings or write the in-code defaults on first launch
- [ ] Update `Views/ControlPanel.swift` so the Emission slider's range comes from `state.settings.emissionRange` (not hardcoded `10...400`)
- [ ] Verify clean build, then verify persistence end-to-end (see Verification below)
- [ ] Commit: `feat: persist editor settings via BlobStore`

## Context

V1a landed (commit `2b4f754`) with the editor showing a campfire emitter and one working slider. Reviewing the result, the UI code uses inline magic numbers (`16`, `38`, `72`, `320`, `0.55`, `0.4`, `0.85`), inline strings (`"Emission: %.0f/s"`), and a hardcoded slider range (`10...400`). All of these multiply as the other 5 sliders, shape picker, and save/load buttons land — so the cleanup is best done now, before the patterns get cargo-culted into V1b/c/d.

The slider-range literal is the pointed example: a particle editor's whole reason for existing is letting the user tune ranges. Hardcoding them makes the editor's own knobs un-tunable. Threading them through a `Settings: Codable` model loaded from `BlobStore` from day one means:

1. The persistence layer (`BlobStore`/`CodableBlobStore`) gets a real working consumer (which validates the layer exists for a reason).
2. When the eventual settings UI lands, it writes through the same path the load uses — no rewiring.
3. The user gets a real `editor.json` file on disk to inspect and hand-edit if they ever want.

No settings UI in this plan. Editing ranges from the app is V1.5 work that comes after V1b/c land.

## File layout after this work

```
LiquidMetal2D-ParticleEditor/
├── LiquidMetal2D_ParticleEditorApp.swift
├── Assets.xcassets/
├── Models/
│   ├── EditorState.swift
│   └── Settings.swift                ← NEW
├── Scene/
│   ├── AppEditorServices.swift
│   ├── EditorScene.swift
│   ├── EditorSceneType.swift
│   ├── EditorServices.swift
│   └── ParticleEditorVC.swift
├── Strings/                          ← NEW folder
│   └── EditorStrings.swift
├── Theme/                            ← NEW folder
│   └── UIConstants.swift
└── Views/
    ├── ContentView.swift
    ├── ControlPanel.swift
    └── ParticleEditorView.swift
```

## Detailed work

### Part A — Constants and strings

**`Theme/UIConstants.swift`** — namespaced enum, grouped by usage:

```swift
import SwiftUI

enum UIConstants {
    // Panel
    static let panelWidth: CGFloat = 320
    static let panelTopInset: CGFloat = 72         // clears the floating toggle button
    static let panelEdgePadding: CGFloat = 16

    // Toggle button
    static let toggleButtonSize: CGFloat = 38
    static let toggleIconSize: CGFloat = 18
    static let toggleButtonOpacity: Double = 0.55
    static let toggleEdgePadding: CGFloat = 16

    // Animation
    static let panelAnimationResponse: Double = 0.4
    static let panelAnimationDamping: Double = 0.85

    // Slider rows
    static let sliderRowSpacing: CGFloat = 16
    static let sliderLabelSpacing: CGFloat = 4
}
```

**`Strings/EditorStrings.swift`** — Swift enum with formatter functions. Promote to `Localizable.xcstrings` later if the app ever ships internationally; not worth the friction now.

```swift
import Foundation

enum EditorStrings {
    static func emission(_ value: Float) -> String {
        String(format: "Emission: %.0f/s", value)
    }
}
```

**Update `Views/ContentView.swift`** — every literal becomes a `UIConstants.X` reference. Animation: `.spring(response: UIConstants.panelAnimationResponse, dampingFraction: UIConstants.panelAnimationDamping)`. Button: `UIConstants.toggleButtonSize` for the frame, `UIConstants.toggleIconSize` for the icon, etc.

**Update `Views/ControlPanel.swift`** — paddings become `UIConstants.X`; the emission text becomes `EditorStrings.emission(state.emissionRate)`.

### Part B — Settings + persistence

**`Models/Settings.swift`** — Codable struct, default values inline. Codable + property defaults means future range additions (speedRange, scaleRange, etc.) decode missing keys as defaults, so older settings files keep working.

```swift
import Foundation

struct Settings: Codable {
    var emissionRange: ClosedRange<Float> = 10...400
    // Future: speedRange, scaleRange, lifetimeRange, spreadRange, gravityRange.
}
```

`ClosedRange<Float>` is `Codable` automatically (both bounds are Codable scalars).

**`Models/EditorState.swift`** — gain `var settings: Settings = Settings()`. Initialized to in-code defaults; replaced by the load result during `ParticleEditorVC.viewDidLoad()`.

```swift
@Observable
final class EditorState {
    var emissionRate: Float = 140
    var settings: Settings = Settings()
}
```

**`Scene/ParticleEditorVC.swift`** — at the top of `viewDidLoad()`, before the engine wiring, set up the BlobStore and either load an existing settings file or save the defaults:

```swift
let settingsStore = CodableBlobStore<Settings>(
    store: FileBlobStore(subdirectory: "settings"))

if let saved = try? settingsStore.get(key: "editor") {
    state.settings = saved
} else {
    // First launch — persist the in-code defaults so an editable file
    // exists on disk for inspection / hand-tuning.
    try? settingsStore.put(state.settings, key: "editor")
}
```

`FileBlobStore(subdirectory: "settings")` writes to `Documents/settings/editor.json`. `try?` on the put means a transient I/O failure on first launch is logged but doesn't crash; the next successful save will create the file. (Reasonable trade for a personal tool; not the right call for a multi-user app.)

**`Views/ControlPanel.swift`** — the emission slider's `in:` argument changes from `10...400` to `state.settings.emissionRange`:

```swift
Slider(value: $state.emissionRange, in: state.settings.emissionRange)
```

Range comes from settings; live value still goes to `EditorState.emissionRate` and reaches the emitter through `EditorServices` as today.

## Critical files to modify

- `LiquidMetal2D-ParticleEditor/Theme/UIConstants.swift` (new)
- `LiquidMetal2D-ParticleEditor/Strings/EditorStrings.swift` (new)
- `LiquidMetal2D-ParticleEditor/Models/Settings.swift` (new)
- `LiquidMetal2D-ParticleEditor/Models/EditorState.swift`
- `LiquidMetal2D-ParticleEditor/Scene/ParticleEditorVC.swift`
- `LiquidMetal2D-ParticleEditor/Views/ContentView.swift`
- `LiquidMetal2D-ParticleEditor/Views/ControlPanel.swift`

## Engine APIs reused (no engine change needed)

- `LiquidMetal2D.BlobStore` protocol — `Sources/LiquidMetal2D/persistence/BlobStore.swift`
- `LiquidMetal2D.FileBlobStore` — `Sources/LiquidMetal2D/persistence/FileBlobStore.swift` — `init(subdirectory:)` writes to `Documents/<subdirectory>/`
- `LiquidMetal2D.CodableBlobStore<T>` — `Sources/LiquidMetal2D/persistence/CodableBlobStore.swift` — JSON encode/decode wrapper around any `BlobStore`

## Verification

### Part A
1. Clean build (Cmd+Shift+K, Cmd+B). Should succeed with zero warnings.
2. Run on iPad simulator. Visual state matches commit `2b4f754` exactly — slider, panel, toggle button, frosted overlay, animation timing all unchanged.

### Part B
1. **First launch**: delete the app from the simulator, then run. Verify the slider behaves identically. Then check that the settings file got written:
   ```bash
   xcrun simctl get_app_container booted com.mattcasanova.LiquidMetal2DParticleEditor data
   # cd into that path, then:
   ls Documents/settings/         # should show: editor.json
   cat Documents/settings/editor.json
   # expect: {"emissionRange":{"lowerBound":10,"upperBound":400}}
   ```
2. **Second launch**: rebuild without deleting. Settings file persists; app loads from it.
3. **Hand-edit test**: with the app stopped, edit `Documents/settings/editor.json` to set `"upperBound":1000`. Relaunch the app. Drag the emission slider to its right edge — it should now read 1000/s instead of 400/s. Confirms the load-from-file path is wired correctly.
4. Quit and relaunch — value range stays 10...1000 (loaded from the file you edited).

## Out of scope (next plans)

- **V1b** — speed/scale/lifetime/spread/gravity sliders. Each adds a `Float` to `EditorState`, a `ClosedRange<Float>` to `Settings`, and a row to `ControlPanel`. Mechanical extension of the pattern this plan establishes.
- **V1c** — shape picker (point/line/box/circle) + shape-specific params.
- **V1d** — `ParticlePreset: Codable` + Save/Load buttons via `DocumentIO` (user-controlled persistence, distinct from the settings file which is app-controlled).
- **V1.5** — settings UI (sheet or expandable panel section to edit ranges from inside the app).
- Engine issue **#119** — rename the engine's `State` protocol to `BehaviorState` so the SwiftUI/engine collision goes away and `ParticleEditorView.swift` can be inlined into `ContentView.swift`.
