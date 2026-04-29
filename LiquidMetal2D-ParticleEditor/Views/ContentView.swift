//
//  ContentView.swift
//  LiquidMetal2D-ParticleEditor
//
//  Top-level screen layout: full-bleed Metal preview as the background,
//  animated SwiftUI control panel as an overlay on the right. Owns the
//  @Observable EditorState and the panel's open/closed flag.
//
//  The Metal pane never resizes — the panel slides over it instead. That
//  keeps the engine's viewport stable and eliminates the layout flash
//  that happened when the HStack reflowed mid-animation.
//

import SwiftUI

struct ContentView: View {
    @State private var state = EditorState()
    @State private var isPanelOpen = true

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ParticleEditorView(state: state)
                .ignoresSafeArea()

            if isPanelOpen {
                ControlPanel(state: state)
                    .frame(width: UIConstants.panelWidth)
                    .frame(maxHeight: .infinity)
                    .transition(.move(edge: .trailing))
                    .ignoresSafeArea()
            }

            Button {
                withAnimation(
                    .spring(
                        response: UIConstants.panelAnimationResponse,
                        dampingFraction: UIConstants.panelAnimationDamping)
                ) {
                    isPanelOpen.toggle()
                }
            } label: {
                Image(systemName: isPanelOpen
                    ? "sidebar.right"
                    : "sidebar.left")
                    .font(.system(
                        size: UIConstants.toggleIconSize,
                        weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(
                        width: UIConstants.toggleButtonSize,
                        height: UIConstants.toggleButtonSize)
                    .background(.black.opacity(UIConstants.toggleButtonOpacity))
                    .background(.ultraThinMaterial, in: .circle)
                    .clipShape(.circle)
            }
            .padding(.top, UIConstants.toggleEdgePadding)
            .padding(.trailing, UIConstants.toggleEdgePadding)
        }
    }
}

#Preview {
    ContentView()
}
