//
//  UIConstants.swift
//  LiquidMetal2D-ParticleEditor
//
//  Layout, sizing, opacity, and animation tokens consumed by SwiftUI
//  views. Keeping the literals out of view bodies means the whole
//  editor's visual style can be retuned from one file.
//

import SwiftUI

enum UIConstants {
    // MARK: - Panel
    static let panelWidth: CGFloat = 320
    static let panelTopInset: CGFloat = 72            // clears the floating toggle button
    static let panelEdgePadding: CGFloat = 16

    // MARK: - Toggle button
    static let toggleButtonSize: CGFloat = 38
    static let toggleIconSize: CGFloat = 18
    static let toggleButtonOpacity: Double = 0.55
    static let toggleEdgePadding: CGFloat = 16

    // MARK: - Animation
    static let panelAnimationResponse: Double = 0.4
    static let panelAnimationDamping: Double = 0.85

    // MARK: - Slider rows
    static let sliderRowSpacing: CGFloat = 16
    static let sliderLabelSpacing: CGFloat = 4
}
