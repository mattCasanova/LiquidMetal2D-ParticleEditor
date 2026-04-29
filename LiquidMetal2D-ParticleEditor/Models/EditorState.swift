//
//  EditorState.swift
//  LiquidMetal2D-ParticleEditor
//
//  @Observable model the SwiftUI views bind to and the engine scene
//  reads each frame.
//
//  Two distinct concerns live here:
//    - `settings`: editor preferences (slider bounds), persisted in
//      app-controlled `editor.json` via BlobStore.
//    - `effect`:   the particle effect being designed, persisted to
//      user-chosen `.particleeffect` files via DocumentIO.
//

import Foundation

@Observable
final class EditorState {
    var settings: Settings = Settings()
    var effect: ParticleEffect = ParticleEffect()
}
