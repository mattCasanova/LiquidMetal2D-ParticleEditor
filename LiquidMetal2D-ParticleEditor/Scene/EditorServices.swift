//
//  EditorServices.swift
//  LiquidMetal2D-ParticleEditor
//
//  App-level extension of SceneServices that adds the editor's @Observable
//  state to the bag the engine passes into scenes. Scenes downcast their
//  SceneServices to this protocol to read the live state each frame.
//

import LiquidMetal2D

protocol EditorServices: SceneServices {
    var state: EditorState { get }
}
