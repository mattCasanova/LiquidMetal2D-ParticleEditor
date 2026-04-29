//
//  Settings.swift
//  LiquidMetal2D-ParticleEditor
//
//  Persisted editor configuration. Holds the bounds of every tunable
//  range so the user can hand-edit Documents/settings/editor.json or,
//  later, change them through a settings UI without touching code.
//
//  Codable + property-defaulted struct: when future ranges are added,
//  older saved files decode missing keys as their in-code defaults,
//  so existing settings files keep working across versions.
//

import Foundation

struct Settings: Codable {
    var emissionRange: ClosedRange<Float> = 10...400
}
