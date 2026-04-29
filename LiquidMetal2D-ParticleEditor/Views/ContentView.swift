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
                    .frame(width: 320)
                    .frame(maxHeight: .infinity)
                    .transition(.move(edge: .trailing))
                    .ignoresSafeArea()
            }

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isPanelOpen.toggle()
                }
            } label: {
                Image(systemName: isPanelOpen
                    ? "sidebar.right"
                    : "sidebar.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.black.opacity(0.55))
                    .background(.ultraThinMaterial, in: .circle)
                    .clipShape(.circle)
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
    }
}

#Preview {
    ContentView()
}
