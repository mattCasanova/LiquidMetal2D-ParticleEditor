//
//  AppEditorServices.swift
//  LiquidMetal2D-ParticleEditor
//
//  Concrete EditorServices the editor wires into the engine via
//  DefaultEngine's buildServices closure. Holds engine-built primitives
//  and the editor's state.
//

import LiquidMetal2D

final class AppEditorServices: EditorServices {
    let renderer: Renderer
    let input: InputReader
    let sceneMgr: SceneManager
    let documents: DocumentIO
    let state: EditorState

    init(
        renderer: Renderer,
        input: InputReader,
        sceneMgr: SceneManager,
        documents: DocumentIO,
        state: EditorState
    ) {
        self.renderer = renderer
        self.input = input
        self.sceneMgr = sceneMgr
        self.documents = documents
        self.state = state
    }
}
