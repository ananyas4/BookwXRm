import ARKit
import RealityKit
import SwiftUI

class ImageTracking {
    private var session: ARKitSession?
    private var imageInfo: ImageTrackingProvider?
    private var entityMap: [UUID: ModelEntity] = [:]
    private var rootEntity = Entity()

    init() {
        setupImageTracking()
    }

    func setupImageTracking() {
        session = ARKitSession()
        imageInfo = ImageTrackingProvider(
            referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "AR Resources")
        )

        if ImageTrackingProvider.isSupported {
            Task {
                do {
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
        if entityMap[anchor.id] == nil {
            let entity = ModelEntity(mesh: .generateSphere(radius: 0.05))
            entityMap[anchor.id] = entity
            rootEntity.addChild(entity)
        }
        
        if anchor.isTracked {
            entityMap[anchor.id]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
        }
    }
}
