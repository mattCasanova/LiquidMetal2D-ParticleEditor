//
//  ParticleEditorView.swift
//  LiquidMetal2D-ParticleEditor
//
//  SwiftUI host for the engine-backed ParticleEditorVC. Keeps the
//  LiquidMetal2D import out of ContentView.swift so SwiftUI's @State
//  property wrapper isn't shadowed by the engine's State protocol.
//  (Once #119 lands and the engine's State is renamed BehaviorState,
//  this wrapper can be inlined into ContentView.)
//

import SwiftUI
import LiquidMetal2D

struct ParticleEditorView: View {
    let state: EditorState

    var body: some View {
        LiquidView { ParticleEditorVC(state: state) }
    }
}
