//
//  EditorScene.swift
//  LiquidMetal2D-ParticleEditor
//
//  The single scene the editor runs. Owns the live emitter, registers the
//  particle shader, and applies EditorState values to the emitter each
//  frame so SwiftUI slider drags feed straight into the simulation.
//

import LiquidMetal2D

final class EditorScene: DefaultScene {
    override class var sceneType: any SceneType { EditorSceneType.editor }

    private let distance: Float = 40
    private var particleShader: ParticleShader!
    private var emitterObj: GameObj!

    private let fireStartColor = Vec4(1.0, 0.55, 0.15, 0.7)
    private let fireStartVar   = Vec4(1.0, 0.85, 0.20, 0.7)
    private let fireEndColor   = Vec4(0.9, 0.10, 0.00, 0.0)
    private let fireEndVar     = Vec4(0.5, 0.00, 0.00, 0.0)

    override func initialize(services: SceneServices) {
        super.initialize(services: services)

        renderer.setCamera(point: Vec3(0, 0, distance))
        renderer.setDefaultPerspective()
        renderer.setClearColor(color: Vec3(0.02, 0.02, 0.05))

        guard let defaultRenderer = renderer as? DefaultRenderer else {
            fatalError("EditorScene requires DefaultRenderer")
        }
        particleShader = ParticleShader(
            renderCore: defaultRenderer.renderCore,
            maxObjects: 500)
        renderer.register(shader: particleShader)

        createEmitter()
    }

    override func update(dt: Float) {
        let emitter = emitterObj.get(ParticleEmitterComponent.self)

        if let touch = input.getWorldTouch(forZ: 0) {
            emitterObj.position.set(touch.x, touch.y)
        }

        if let editor = services as? EditorServices, let emitter {
            emitter.emissionRate = editor.state.emissionRate
        }

        emitter?.update(dt: dt)
    }

    override func draw() {
        guard renderer.beginPass() else { return }
        renderer.usePerspective()
        renderer.useShader(particleShader)
        renderer.submit(objects: objects)
        renderer.endPass()
    }

    override func shutdown() {
        super.shutdown()
        renderer.unregister(shader: particleShader)
    }

    private func createEmitter() {
        let obj = GameObj()
        obj.position.set(0, -6)

        obj.add(ParticleEmitterComponent(
            parent: obj,
            maxParticles: 400,
            textureID: renderer.defaultParticleTextureId,
            emissionRate: 140,
            localOffset: Vec2(),
            lifetimeRange: 0.8...1.6,
            speedRange: 6...14,
            angleRange: (.pi / 2 - 0.25)...(.pi / 2 + 0.25),
            scaleRange: 4...8,
            angularVelocityRange: -1...1,
            startColor: fireStartColor,
            startColorVariation: fireStartVar,
            endColor: fireEndColor,
            endColorVariation: fireEndVar,
            correlatedColorVariation: true,
            gravity: Vec2(0, 1)))

        objects.append(obj)
        emitterObj = obj
    }
}
