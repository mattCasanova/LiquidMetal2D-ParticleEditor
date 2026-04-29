//
//  ControlPanel.swift
//  LiquidMetal2D-ParticleEditor
//
//  Sidebar of SwiftUI controls bound to the editor's @Observable state.
//  Slider drags propagate through @Bindable to EditorState; the running
//  scene reads those values each frame and applies them to the live
//  emitter.
//
//  Forces a dark color scheme so .regularMaterial renders as a
//  black-frosted overlay and text auto-contrasts to white.
//

import SwiftUI

struct ControlPanel: View {
    @Bindable var state: EditorState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Emission: \(Int(state.emissionRate))/s")
                    .font(.system(.body, design: .monospaced))
                Slider(value: $state.emissionRate, in: 10...400)
            }

            Spacer()
        }
        .padding(.top, 72)             // leave space for the floating toggle button
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .environment(\.colorScheme, .dark)
    }
}
