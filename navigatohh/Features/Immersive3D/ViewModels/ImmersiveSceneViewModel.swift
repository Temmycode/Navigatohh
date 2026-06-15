//
//  ImmersiveSceneViewModel.swift
//  navigatohh
//
//  Backs the experimental RealityKit scene. Kept intentionally small — this is the seam
//  where the custom 3D experiences for Bashorun/Bodija will grow.
//

import Observation

@MainActor
@Observable
final class ImmersiveSceneViewModel {
    var rotation: Double = 0

    func tick() {
        rotation += 0.01
    }
}
