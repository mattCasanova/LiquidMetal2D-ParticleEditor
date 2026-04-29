//
//  EditorScene.swift
//  LiquidMetal2D-ParticleEditor
//
//  The single scene the editor runs. Owns the live emitter, registers the
//  particle shader, and applies EditorState.effect values to the live
//  emitter each frame so SwiftUI slider drags feed straight into the
//  simulation. `rebuild()` tears down and reconstructs the shader and
//  emitter — used both at scene init and after a Load operation, when
//  the loaded effect may need different shader/emitter buffer sizes.
//

import LiquidMetal2D

final class EditorScene: DefaultScene {
    override class var sceneType: any SceneType { EditorSceneType.editor }

    private let distance: Float = 40
    private var particleShader: ParticleShader?
    private var emitterObj: GameObj?

    override func initialize(services: SceneServices) {
        super.initialize(services: services)

        renderer.setCamera(point: Vec3(0, 0, distance))
        renderer.setDefaultPerspective()
        renderer.setClearColor(color: Vec3(0.02, 0.02, 0.05))

        rebuild()
    }

    /// Tears down the existing shader and emitter (if any) and rebuilds
    /// them from `state.effect`. Called once at scene init and again
    /// after Load to pick up potentially different shader maxObjects /
    /// emitter maxParticles values from the loaded effect.
    func rebuild() {
        guard let editor = services as? EditorServices else { return }
        guard let defaultRenderer = renderer as? DefaultRenderer else {
            fatalError("EditorScene requires DefaultRenderer")
        }

        // Tear down any existing shader/emitter
        if let shader = particleShader {
            renderer.unregister(shader: shader)
        }
        objects.removeAll()

        let effect = editor.state.effect

        let shader = ParticleShader(
            renderCore: defaultRenderer.renderCore,
            maxObjects: effect.shader.maxObjects)
        renderer.register(shader: shader)
        particleShader = shader

        // V1 builds only the first emitter — multi-emitter UI is later.
        guard let cfg = effect.emitters.first else { return }
        emitterObj = makeEmitterObject(from: cfg)
        if let obj = emitterObj { objects.append(obj) }
    }

    override func update(dt: Float) {
        if let touch = input.getWorldTouch(forZ: 0) {
            emitterObj?.position.set(touch.x, touch.y)
        }

        if let editor = services as? EditorServices,
           let cfg = editor.state.effect.emitters.first,
           let emitter = emitterObj?.get(ParticleEmitterComponent.self) {
            // Apply current effect values to the live emitter every frame.
            // Slider drags propagate immediately; loaded effects show up
            // on the next frame after rebuild() finishes.
            emitter.emissionRate = cfg.emissionRate
            emitter.localOffset = cfg.localOffset
            emitter.shape = cfg.shape
            emitter.lifetimeRange = cfg.lifetimeRange
            emitter.speedRange = cfg.speedRange
            emitter.angleRange = cfg.angleRange
            emitter.scaleRange = cfg.scaleRange
            emitter.angularVelocityRange = cfg.angularVelocityRange
            emitter.startColor = cfg.startColor
            emitter.startColorVariation = cfg.startColorVariation
            emitter.endColor = cfg.endColor
            emitter.endColorVariation = cfg.endColorVariation
            emitter.correlatedColorVariation = cfg.correlatedColorVariation
            emitter.gravity = cfg.gravity
        }

        emitterObj?.get(ParticleEmitterComponent.self)?.update(dt: dt)
    }

    override func draw() {
        guard renderer.beginPass() else { return }
        renderer.usePerspective()
        if let shader = particleShader {
            renderer.useShader(shader)
        }
        renderer.submit(objects: objects)
        renderer.endPass()
    }

    override func shutdown() {
        super.shutdown()
        if let shader = particleShader {
            renderer.unregister(shader: shader)
            particleShader = nil
        }
    }

    private func makeEmitterObject(from cfg: EmitterConfig) -> GameObj {
        let obj = GameObj()
        obj.position.set(0, -6)

        obj.add(ParticleEmitterComponent(
            parent: obj,
            maxParticles: cfg.maxParticles,
            textureID: renderer.defaultParticleTextureId,
            emissionRate: cfg.emissionRate,
            localOffset: cfg.localOffset,
            shape: cfg.shape,
            lifetimeRange: cfg.lifetimeRange,
            speedRange: cfg.speedRange,
            angleRange: cfg.angleRange,
            scaleRange: cfg.scaleRange,
            angularVelocityRange: cfg.angularVelocityRange,
            startColor: cfg.startColor,
            startColorVariation: cfg.startColorVariation,
            endColor: cfg.endColor,
            endColorVariation: cfg.endColorVariation,
            correlatedColorVariation: cfg.correlatedColorVariation,
            gravity: cfg.gravity))

        return obj
    }
}
