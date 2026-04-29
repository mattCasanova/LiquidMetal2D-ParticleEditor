//
//  EditorStrings.swift
//  LiquidMetal2D-ParticleEditor
//
//  User-facing strings for the editor. Plain Swift enum for now —
//  promote to Localizable.xcstrings if/when the app ships
//  internationally.
//

import Foundation

enum EditorStrings {
    static func emission(_ value: Float) -> String {
        String(format: "Emission: %.0f/s", value)
    }
}
