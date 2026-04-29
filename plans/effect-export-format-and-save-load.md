# Particle effect export format + Save/Load

Scope: define the wire format the editor produces (`ParticleEffect`/`ShaderConfig`/`EmitterConfig`), refactor editor internals to use it as the source of truth, then wire Save/Load buttons via `DocumentIO`. Spans both repos — engine gets a small `Codable` addition, editor gets the bigger refactor.

## Checklist

### Engine (LiquidMetal2D)
- [ ] Add `Codable` conformance to `EmitterShape` (`Sources/LiquidMetal2D/components/ParticleEmitterComponent.swift`)
- [ ] Build + tests pass
- [ ] Tag `0.14.0`, push (`feat: add Codable to EmitterShape`)
- [ ] File matching engine issue, link in commit

### Editor — data model
- [ ] Bump editor's `Package.swift` SPM dep to `0.14.0`, re-resolve
- [ ] Create `Models/ParticleEffect.swift` — three Codable structs (see below)
- [ ] Refactor `Models/EditorState.swift` — replace `var emissionRate: Float` with `var effect: ParticleEffect`
- [ ] Refactor `Scene/EditorScene.swift` — emitter built from `state.effect.emitters[0]`; reads `state.effect` values each frame
- [ ] Refactor `Views/ControlPanel.swift` — slider binds to `$state.effect.emitters[0].emissionRate`
- [ ] Build + run; visual + behavior parity with `3e74045`
- [ ] Commit: `refactor: thread editor state through ParticleEffect`

### Editor — Save/Load via DocumentIO
- [ ] Add Save / Load buttons to `Views/ControlPanel.swift` (top of panel, above sliders)
- [ ] Wire Save → `services.documents.save(data:suggestedFilename:)` with JSON-encoded `state.effect`
- [ ] Wire Load → `services.documents.load(contentTypes:)` then decode + rebuild scene from new effect
- [ ] File extension: `.particleeffect` (custom UTI not registered yet — list `.json` as accepted load type for V1)
- [ ] Handle `DocumentIO.Error.userCancelled` (silent no-op) and decode errors (alert)
- [ ] Build + run; round-trip an effect file: tweak slider, save, reset app, load, verify slider state restored
- [ ] Commit: `feat: save and load particle effects via DocumentIO`

## Context

The editor's reason for existing is to produce particle effect files that games consume. Today the editor is mostly cosmetic: the emitter is hardcoded in `EditorScene.createEmitter()`, and the slider mutates a standalone `EditorState.emissionRate: Float` that never reaches a file. There's no exported artifact.

This plan flips the architecture so the editor *is* a designer for a Codable wire format. The important shifts:

1. **`ParticleEffect` becomes the source of truth.** It bundles a shader config (where `maxObjects` belongs — it's a shader concern, not an emitter concern) and a *list* of emitter configs (`emitters: [EmitterConfig]`, future-proofing for multi-emitter effects like fire+smoke+sparks).

2. **Editor mutations target `state.effect`.** Sliders bind to nested fields. The scene reads `state.effect.emitters[0].emissionRate` each frame and applies it to the live emitter. No standalone `EditorState.emissionRate` anymore.

3. **Save/Load is just JSON-encoding `state.effect`.** Once the architecture's right, the buttons are ~30 lines.

4. **Distinct from existing `Settings`.** `Settings` (already shipped) holds *editor preferences* like slider bounds, lives in `Documents/settings/editor.json`, app-controlled. `ParticleEffect` holds *effect data*, lives in user-chosen locations via `DocumentIO`, user-controlled. Two different files, two different persistence tiers — this is exactly the distinction the engine's two-tier persistence layer was designed for.

After this lands, V1b (the other 5 sliders) becomes mechanical: each slider binds to a different field on `state.effect.emitters[0]`. V1c (shape picker) flips a case on `state.effect.emitters[0].shape`. Multi-emitter UI (later) appends to `state.effect.emitters`. Same skeleton, more knobs.

## Engine change

**Modify `Sources/LiquidMetal2D/components/ParticleEmitterComponent.swift`:**

```swift
// Currently:
public enum EmitterShape: Sendable {
    case point
    case line(from: Vec2, to: Vec2)
    case box(halfExtents: Vec2)
    case circle(radius: Float)
}

// After:
public enum EmitterShape: Sendable, Codable {
    case point
    case line(from: Vec2, to: Vec2)
    case box(halfExtents: Vec2)
    case circle(radius: Float)
}
```

Swift auto-synthesizes `Codable` for enums with associated values when all associated values are `Codable`. `Vec2` (`simd_float2`) is `Codable` since iOS 13; `Float` is `Codable`. So conformance is a one-word addition; no manual `init(from:)` / `encode(to:)` required.

**Why a minor bump (0.14.0) and not patch:** adding a protocol conformance is technically additive, but the engine pre-1.0 versioning has been treating any meaningful API surface change as a minor bump. Consistent.

## Data model

**New file `LiquidMetal2D-ParticleEditor/Models/ParticleEffect.swift`:**

```swift
import Foundation
import LiquidMetal2D

/// Top-level export format. One file = one ParticleEffect = one shader
/// config + a list of emitter configs that share that shader.
struct ParticleEffect: Codable {
    var shader: ShaderConfig = ShaderConfig()
    var emitters: [EmitterConfig] = [EmitterConfig()]
}

/// Per-shader config. `maxObjects` is the shader's uniform-buffer
/// ceiling — fixed at construction, so it's a setup-time knob, not a
/// real-time slider. Future: blendMode (additive vs alpha).
struct ShaderConfig: Codable {
    var maxObjects: Int = 2000
}

/// Per-emitter config. Mirrors ParticleEmitterComponent's tunable
/// surface; default values are the campfire emitter from the demo.
struct EmitterConfig: Codable {
    var maxParticles: Int = 400
    var emissionRate: Float = 140
    var localOffset: Vec2 = Vec2()
    var shape: EmitterShape = .point
    var lifetimeRange: ClosedRange<Float> = 0.8...1.6
    var speedRange: ClosedRange<Float> = 6...14
    var angleRange: ClosedRange<Float> = (.pi / 2 - 0.25)...(.pi / 2 + 0.25)
    var scaleRange: ClosedRange<Float> = 4...8
    var angularVelocityRange: ClosedRange<Float> = -1...1
    var startColor: Vec4 = Vec4(1.0, 0.55, 0.15, 0.7)
    var startColorVariation: Vec4? = Vec4(1.0, 0.85, 0.20, 0.7)
    var endColor: Vec4 = Vec4(0.9, 0.10, 0.00, 0.0)
    var endColorVariation: Vec4? = Vec4(0.5, 0.00, 0.00, 0.0)
    var correlatedColorVariation: Bool = true
    var gravity: Vec2 = Vec2(0, 1)
}
```

**Notes:**
- `textureID` is intentionally not in `EmitterConfig`. Texture identity isn't portable across runs — it's a `TextureManager`-assigned int. V1 always uses `renderer.defaultParticleTextureId`. When custom textures land, we'll add a `texture: TextureRef` field that holds a name/path, resolved at load time.
- `maxParticles` lives on emitter, `maxObjects` lives on shader. Distinct concepts: pool size vs uniform-buffer ceiling.
- All ranges, optionals, and primitive types are already `Codable`. The only engine type we use, `EmitterShape`, becomes `Codable` in the engine PR above. `Vec2`/`Vec4` (simd) are `Codable` for free.

## Editor refactor

**`Models/EditorState.swift`:** swap the standalone `emissionRate` for `effect`.

```swift
@Observable
final class EditorState {
    var settings: Settings = Settings()
    var effect: ParticleEffect = ParticleEffect()
}
```

**`Scene/EditorScene.swift`:** `createEmitter()` reads from `state.effect.emitters[0]` (cast services to EditorServices first). `update(dt:)` keeps the live emitter synced with whatever the slider just changed:

```swift
override func update(dt: Float) {
    let emitter = emitterObj.get(ParticleEmitterComponent.self)

    if let touch = input.getWorldTouch(forZ: 0) {
        emitterObj.position.set(touch.x, touch.y)
    }

    if let editor = services as? EditorServices,
       let emitter,
       let cfg = editor.state.effect.emitters.first {
        emitter.emissionRate = cfg.emissionRate
        // ... in V1b, copy the rest of the fields here
    }

    emitter?.update(dt: dt)
}
```

**`Views/ControlPanel.swift`:** binding becomes nested.

```swift
Slider(value: $state.effect.emitters[0].emissionRate,
       in: state.settings.emissionRange)
```

`@Bindable` + `@Observable` propagates writes through array subscript — verified by SwiftUI docs for value-type collections. If it doesn't work cleanly in practice, fallback is a computed `primaryEmitter` property on `EditorState` that hides the subscript.

## Save/Load

**`Views/ControlPanel.swift`** gains a top action row above the sliders:

```swift
HStack {
    Button("Load") { Task { await load() } }
    Button("Save") { Task { await save() } }
}
```

Both call into closures the panel receives from `ParticleEditorView`, which has access to the editor's `DocumentIO` instance through the shared `EditorServices`. (Alternative: pass `DocumentIO` into the panel directly. Decide during implementation — simpler is fine.)

**Save:**
```swift
let data = try JSONEncoder().encode(state.effect)
try await documents.save(data: data, suggestedFilename: "MyEffect.particleeffect")
```

**Load:**
```swift
let data = try await documents.load(contentTypes: [.json])
state.effect = try JSONDecoder().decode(ParticleEffect.self, from: data)
```

After load, the scene needs to rebuild — the existing live emitter was constructed with the *old* effect's `maxParticles` and the shader was constructed with the *old* `maxObjects`. Easiest path: scene observes `state.effect` and on change, tears down + rebuilds emitter+shader. Less ideal but works for V1: pop+push the editor scene to force re-init. Cleanest: refactor `EditorScene.createEmitter()` and `register(shader:)` into a `rebuild()` method called from both `initialize` and on-load.

I'll go with **rebuild()** — adds maybe 20 lines, keeps the rebuild explicit.

**Error handling:**
- `DocumentIO.Error.userCancelled` on save/load → silent no-op.
- Decode failure on load → SwiftUI alert via `@State var loadError: Error?`. Effect remains unchanged.

**File extension:**
- `.particleeffect` (suggested filename includes the extension)
- For V1, accept `.json` as the load filter (`UTType.json`). Custom UTI registration via `Info.plist` adds noise we don't need yet — defer.

## Critical files to modify

**Engine:**
- `Sources/LiquidMetal2D/components/ParticleEmitterComponent.swift` — add `, Codable` to `EmitterShape`'s conformance list

**Editor (new):**
- `LiquidMetal2D-ParticleEditor/Models/ParticleEffect.swift`

**Editor (modified):**
- `LiquidMetal2D-ParticleEditor.xcodeproj/project.pbxproj` — bump SPM minimumVersion 0.13.0 → 0.14.0
- `LiquidMetal2D-ParticleEditor/Models/EditorState.swift`
- `LiquidMetal2D-ParticleEditor/Scene/EditorScene.swift`
- `LiquidMetal2D-ParticleEditor/Views/ControlPanel.swift`
- `LiquidMetal2D-ParticleEditor/Views/ParticleEditorView.swift` — wire Save/Load closures down to ControlPanel (depending on which approach we take)

## Engine APIs reused (no new ones needed)

- `LiquidMetal2D.DocumentIO.save(data:suggestedFilename:)` — `Sources/LiquidMetal2D/persistence/DocumentIO.swift`
- `LiquidMetal2D.DocumentIO.load(contentTypes:)` — same file
- `LiquidMetal2D.ParticleEmitterComponent` init — already has every property the EmitterConfig mirror needs
- `LiquidMetal2D.ParticleShader(renderCore:maxObjects:)` — used at scene construction
- `EditorServices.documents` — already injected via `AppEditorServices`

## Verification

### Engine PR
1. `xcodebuild -scheme LiquidMetal2D -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipPackagePluginValidation test` — all 310+ tests still pass
2. Sanity check: `let s = EmitterShape.line(from: Vec2(0,0), to: Vec2(1,1)); let json = try JSONEncoder().encode(s); let s2 = try JSONDecoder().decode(EmitterShape.self, from: json)` round-trips equal
3. Push tag, confirm GitHub release page shows 0.14.0

### Editor data-model refactor (no save/load yet)
1. Build clean, run on iPad simulator
2. Slider behavior identical to `3e74045` — campfire renders, slider tweaks emission rate
3. Inspect `state.effect.emitters[0].emissionRate` via Xcode's debug view or a print — value matches slider position

### Editor Save/Load
1. Build clean, run
2. **Save round-trip:** drag emission slider to ~50 (so we know we changed something). Tap Save. Pick a Files.app destination. Confirm file appears with `.particleeffect` extension. `cat` the file:
   ```bash
   # find the file in iOS Files inbox or wherever it landed
   ```
   Verify it contains JSON with the modified `emissionRate`.
3. **Load round-trip:** quit the app, relaunch (effect resets to defaults — emission 140). Tap Load. Pick the file just saved. Confirm:
   - Slider snaps to 50
   - Live emitter immediately rebuilds; particles reflect the loaded config
4. **User-cancel:** tap Save → cancel the picker → app stays running, no error dialog
5. **Decode error:** create a junk `.particleeffect` file with `echo "not json" > junk.particleeffect`. Tap Load → pick it → alert appears, effect unchanged

## Out of scope (future plans)

- **V1b** — speed/scale/lifetime/spread/gravity sliders. Mechanical extension: each new slider binds to a field on `state.effect.emitters[0]`. The data model already has those fields with sensible defaults; this is just UI work.
- **V1c** — shape picker (point/line/box/circle radio + shape-specific param fields).
- **V1.5** — settings UI for editing slider bounds (the `Settings` struct from the previous plan).
- **Multi-emitter UI** — list of emitters in the control panel, add/remove buttons, per-emitter accordion. Data model already supports it via `emitters: [EmitterConfig]`.
- **Custom particle textures** — texture ID portability. Add `texture: TextureRef` to `EmitterConfig` storing a name/path; resolve via TextureManager at load time. Probably also engine work to support texture lookup by name.
- **Custom UTI** — register `.particleeffect` as a content type via `Info.plist`. Tightens load filter and lets Files.app show the right icon. Not blocking.
- **Versioned schema** — `ParticleEffect` gains a `version: Int` field, decoder handles migrations. Defer until we have a v2 with breaking changes.
