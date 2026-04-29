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
        VStack(alignment: .leading, spacing: UIConstants.sliderRowSpacing) {
            VStack(alignment: .leading, spacing: UIConstants.sliderLabelSpacing) {
                Text(EditorStrings.emission(state.emissionRate))
                    .font(.system(.body, design: .monospaced))
                Slider(value: $state.emissionRate, in: state.settings.emissionRange)
            }

            Spacer()
        }
        .padding(.top, UIConstants.panelTopInset)
        .padding(.horizontal, UIConstants.panelEdgePadding)
        .padding(.bottom, UIConstants.panelEdgePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .environment(\.colorScheme, .dark)
    }
}
