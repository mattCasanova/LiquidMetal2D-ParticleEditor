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
}
