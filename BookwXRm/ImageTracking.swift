import ARKit
import RealityKit
import SwiftUI

class ImageTracking {
    private var session: ARKitSession?
    private var imageInfo: ImageTrackingProvider?
    private var entityMap: [UUID: ModelEntity] = [:]
    private var rootEntity = Entity()

    init() {
        print("Init Image Tracking")
        setupImageTracking()
    }

    func setupImageTracking() {
        print("Setup Image Tracking")
        session = ARKitSession()
        imageInfo = ImageTrackingProvider(
            referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "AR Resources")
        )

        if ImageTrackingProvider.isSupported {
            Task {
                do {
                    print("ImageTrackingProvider Task Loop")
                    try await session?.run([imageInfo!])
                    for await update in imageInfo!.anchorUpdates {
                        updateImage(update.anchor)
                    }
                } catch {
                    print("Error starting AR session: \(error)")
                }
            }
        }
    }

    func updateImage(_ anchor: ImageAnchor) {
        print("Update Image")
        if entityMap[anchor.id] == nil {
            //let entity = ModelEntity(mesh: .generateSphere(radius: 0.05))
            
            // Create ModelEntity for spawned sphere
            let entity = ModelEntity()
            
            // Define sphere radius, mesh, and material
            let sphereRadius: Float = 0.05
            let sphereMesh = MeshResource.generateSphere(radius: sphereRadius)
            let sphereMaterial = SimpleMaterial(color: .white, isMetallic: false)
            
            // Update entity components
            entity.components.set(ModelComponent(mesh: sphereMesh, materials: [sphereMaterial]))
            entityMap[anchor.id] = entity
            rootEntity.addChild(entity)
        }
        
        if anchor.isTracked {
            entityMap[anchor.id]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
        }
    }
}
