//
//  ImmersiveSceneView.swift
//  navigatohh
//
//  Placeholder RealityKit scene — a rotating 3D landmark block. This is the starting point
//  for the custom immersive/3D features you want to build on top of the Mapbox base.
//

import SwiftUI
import RealityKit

struct ImmersiveSceneView: View {
    @State private var viewModel = ImmersiveSceneViewModel()

    var body: some View {
        ZStack {
            RealityView { content in
                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(makeLandmark())
                content.add(anchor)

                // Simple directional lighting.
                let light = DirectionalLight()
                light.light.intensity = 2500
                light.look(at: .zero, from: [2, 4, 3], relativeTo: nil)
                content.add(light)
            } update: { content in
                guard let entity = content.entities.first?.children.first else { return }
                entity.transform.rotation = simd_quatf(angle: Float(viewModel.rotation), axis: [0, 1, 0])
            }
            .ignoresSafeArea()
            .background(Color.black)

            VStack {
                Spacer()
                Text("Immersive 3D (experimental)")
                    .font(AppTypography.caption)
                    .padding(AppSpacing.sm)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, AppSpacing.lg)
            }
        }
        .navigationTitle("3D")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Drive a gentle rotation. Replace with real interaction/animation later.
            while !Task.isCancelled {
                viewModel.tick()
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func makeLandmark() -> ModelEntity {
        let mesh = MeshResource.generateBox(size: [0.4, 0.6, 0.4], cornerRadius: 0.03)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(AppColors.accent))
        material.roughness = 0.4
        material.metallic = 0.1
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = [0, 0, -1.2]
        return entity
    }
}

#Preview {
    NavigationStack {
        ImmersiveSceneView()
    }
}
