//
//  ImmersiveView.swift
//  BookwXRm
//
//  Created by Ananya on 1/24/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct ImmersiveView: View {
    
    private let session = ARKitSession()
    private let imageTrackingProvider = ImageTrackingProvider(
        referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "AR Resources")
    )
    
    @State private var entityMap: [UUID: ModelEntity] = [:]
    @State private var sphereEntity = ModelEntity()
    
    private let SPHERE_MESH: MeshResource = MeshResource.generateSphere(radius: 0.02)
    
    private let SPHERE_MATERIAL: SimpleMaterial = SimpleMaterial(color: .red, isMetallic: false)

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {

                // Put skybox here.  See example in World project available at
                // https://developer.apple.com/
            }
            sphereEntity = ModelEntity(
                mesh: SPHERE_MESH,
                materials: [SPHERE_MATERIAL]
            )
            content.add(sphereEntity)
            sphereEntity.isEnabled = false
        }.task {
            await runSession()
            await processImageTrackingUpdates()
        }
    }
    
    func runSession() async {
        do {
            if ImageTrackingProvider.isSupported {
                try await session.run([imageTrackingProvider])
            } else {
                print("Image Tracking Provider is NOT Supported.")
            }
        } catch {
            print("Image Tracking Exception: [(type(of: self))] [(#function)] (error)")
        }
    }
    
    func processImageTrackingUpdates() async {
        for await update in imageTrackingProvider.anchorUpdates {
            updateImage(update.anchor)
        }
    }
    
    private func updateImage(_ anchor: ImageAnchor) {

        print("updateImage called")
        if entityMap[anchor.id] == nil {
            print("inside first if")
            entityMap[anchor.id] = sphereEntity
        }
    
        if anchor.isTracked {
            print("inside second if")
            sphereEntity.isEnabled = true
//
//                let imageName = anchor.referenceImage.name!
            // print("anchor image name: " + imageName)

//                if imageName == "They_Live_HERO" {
//                    entityMap[anchor.id]?.model?.mesh = MESH_OBEY
//                    entityMap[anchor.id]?.model?.materials = [MATERIALS_OBEY]
//                } else {
//                    entityMap[anchor.id]?.model?.mesh = MESH_AI
//                    entityMap[anchor.id]?.model?.materials = [MATERIALS_AI]
//                }

            // 1. Get the anchor's transform
            let anchorTransform = Transform(matrix: anchor.originFromAnchorTransform)

            // 2. Define the local offset you’d like in the anchor’s space
            let localOffset = SIMD3<Float>(0.3, 0.0, 0.05)

            // 3. Rotate this offset by the anchor's rotation (quaternion)
            let rotatedOffset = simd_act(anchorTransform.rotation, localOffset)

            // 4. Apply the rotated offset to the anchor's translation
            entityMap[anchor.id]?.transform.translation = anchorTransform.translation + rotatedOffset
//
//            let rotation = simd_quatf(angle: -(.pi / 2), axis: [1, 0, 0])
//            entityMap[anchor.id]?.transform.rotation = transform.rotation * rotation
        } else {
            print("inside else")
            sphereEntity.isEnabled = false
        }
    }
    
}

/*
#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
*/
