//
//  ParticleEditorVC.swift
//  LiquidMetal2D-ParticleEditor
//
//  Owns the engine and serves as the presenting VC for DocumentIO.
//  Hosted inside SwiftUI via LiquidView. Wires the editor's state into
//  the scene through the engine's buildServices hook.
//

import UIKit
import LiquidMetal2D

final class ParticleEditorVC: LiquidViewController {
    private let state: EditorState

    init(state: EditorState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

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
            sceneFactory: sceneFactory,
            buildServices: { [state] r, i, s, d in
                AppEditorServices(
                    renderer: r, input: i, sceneMgr: s,
                    documents: d, state: state)
            })

        gameEngine.run()
    }
}
