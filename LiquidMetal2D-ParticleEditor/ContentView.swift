//
//  ContentView.swift
//  LiquidMetal2D-ParticleEditor
//

import SwiftUI
import LiquidMetal2D

struct ContentView: View {
    var body: some View {
        LiquidView { ParticleEditorVC() }
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
