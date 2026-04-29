//
//  EditorSceneType.swift
//  LiquidMetal2D-ParticleEditor
//
//  Identifier the engine uses to register and look up the editor scene.
//  Single case — the editor is one screen forever — but the engine still
//  expects a SceneType for the SceneFactory to map against.
//

import LiquidMetal2D

enum EditorSceneType: SceneType {
    case editor
}
