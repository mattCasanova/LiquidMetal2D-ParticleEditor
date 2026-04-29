//
//  ParticleEditorVC.swift
//  LiquidMetal2D-ParticleEditor
//
//  V0: Hosts a LiquidMetal2D engine displaying the campfire emitter from
//  the demo's ParticleDemo. No SwiftUI controls yet — this validates the
//  LiquidView bridge and the engine integration before any UI sits on top.
//

import UIKit
import LiquidMetal2D

// MARK: - Scene types

private enum EditorSceneType: SceneType {
    case editor
}

// MARK: - View controller

/// Owns the engine and serves as the presenting VC for ``DocumentIO``.
/// Hosted inside SwiftUI via ``LiquidView``.
final class ParticleEditorVC: LiquidViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let renderer = DefaultRenderer(parentView: view, maxObjects: 100)
        let documents = DocumentIO(presentingVC: self)

        let sceneFactory = SceneFactory()
        sceneFactory.addScene(EditorScene.self)

        gameEngine = DefaultEngine(
            renderer: renderer,
            documents: documents,
            initialSceneType: EditorSceneType.editor,
            sceneFactory: sceneFactory)

        gameEngine.run()
    }
}

// MARK: - Scene

private final class EditorScene: DefaultScene {
    override class var sceneType: any SceneType { EditorSceneType.editor }

    private let distance: Float = 40
    private var particleShader: ParticleShader!
    private var emitterObj: GameObj!

    // Campfire palette — copied from ParticleDemo so we know what good
    // looks like.
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
        if let touch = input.getWorldTouch(forZ: 0) {
            emitterObj.position.set(touch.x, touch.y)
        }
        emitterObj.get(ParticleEmitterComponent.self)?.update(dt: dt)
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
