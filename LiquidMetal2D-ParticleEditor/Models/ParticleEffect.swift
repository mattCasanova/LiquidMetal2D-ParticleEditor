//
//  ParticleEffect.swift
//  LiquidMetal2D-ParticleEditor
//
//  Wire format the editor exports and games consume. One file =
//  one ParticleEffect = one shader config + a list of emitter configs
//  that share that shader.
//
//  Distinct from `Settings`, which holds editor preferences (slider
//  bounds etc.) in app-controlled storage. ParticleEffect is the user's
//  artifact, written to user-chosen locations via DocumentIO.
//

import Foundation
import LiquidMetal2D

/// Top-level export. Saved as JSON with the `.particleeffect` extension.
struct ParticleEffect: Codable {
    var shader: ShaderConfig = ShaderConfig()
    var emitters: [EmitterConfig] = [EmitterConfig()]
}

/// Per-shader config. `maxObjects` is the shader's uniform-buffer
/// ceiling — fixed at construction, so it's a setup-time knob, not a
/// real-time slider.
struct ShaderConfig: Codable {
    var maxObjects: Int = 2000
}

/// Per-emitter config. Mirrors `ParticleEmitterComponent`'s tunable
/// surface; default values reproduce the demo's campfire emitter so a
/// fresh effect renders something immediately.
///
/// `textureID` is intentionally not modeled — runtime IDs aren't
/// portable across launches. The editor always uses the engine's
/// built-in soft-circle particle texture for now. Custom textures
/// land later via a `texture: TextureRef` field that holds a
/// resolvable name/path.
struct EmitterConfig: Codable {
    var maxParticles: Int = 400
    var emissionRate: Float = 140
    var localOffset: Vec2 = Vec2()
    var shape: EmitterShape = .point
    var lifetimeRange: ClosedRange<Float> = 0.8...1.6
    var speedRange: ClosedRange<Float> = 6...14
    var angleRange: ClosedRange<Float> = (Float.pi / 2 - 0.25)...(Float.pi / 2 + 0.25)
    var scaleRange: ClosedRange<Float> = 4...8
    var angularVelocityRange: ClosedRange<Float> = -1...1
    var startColor: Vec4 = Vec4(1.0, 0.55, 0.15, 0.7)
    var startColorVariation: Vec4? = Vec4(1.0, 0.85, 0.20, 0.7)
    var endColor: Vec4 = Vec4(0.9, 0.10, 0.00, 0.0)
    var endColorVariation: Vec4? = Vec4(0.5, 0.00, 0.00, 0.0)
    var correlatedColorVariation: Bool = true
    var gravity: Vec2 = Vec2(0, 1)
}
