//
//  EditorState.swift
//  LiquidMetal2D-ParticleEditor
//
//  @Observable model holding the live emitter's tunable parameters.
//  Owned by ContentView, mutated by SwiftUI controls, read each frame
//  by the editor scene through EditorServices.
//

import Foundation

@Observable
final class EditorState {
    var emissionRate: Float = 140

    /// Persisted settings (slider ranges, etc.). Initialized to in-code
    /// defaults; replaced with the BlobStore-loaded version during
    /// `ParticleEditorVC.viewDidLoad()`.
    var settings: Settings = Settings()
}
