import ARKit
import RealityKit
import SwiftUI

class ImageTracking {
    private var session: ARKitSession?
    private var imageInfo: ImageTrackingProvider?
    private var entityMap: [UUID: ModelEntity] = [:]
    private var rootEntity = Entity()
    private var sphereEntity = ModelEntity()

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
            
            sphereEntity = ModelEntity(mesh: .generateSphere(radius: 0.5))
            sphereEntity.position = [0, 1.5, -1]
            
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

    /*
    func updateImage(_ anchor: ImageAnchor) {
        print("Update Image")
        print("anchor id: ")
        print(anchor.id)
        //if entityMap[anchor.id] == nil {
            print("inside if")
            //let entity = ModelEntity(mesh: .generateSphere(radius: 0.05))
            
            // Create ModelEntity for spawned sphere
            //let entity = ModelEntity()
            
            // Define sphere radius, mesh, and material
            //let sphereRadius: Float = 0.05
           //  let sphereMesh: MeshResource = MeshResource.generateSphere(radius: sphereRadius)
           
            //let sphereMaterial = SimpleMaterial(color: .white, isMetallic: false)
            
            // Update entity components
//            entity.components.set(ModelComponent(mesh: sphereMesh, materials: [sphereMaterial]))
            entityMap[anchor.id] = sphereEntity
            rootEntity.addChild(sphereEntity)
            print("child added")
        //}
        
        if anchor.isTracked {
            entityMap[anchor.id]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
        }
    }
     */
    
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

                let transform = Transform(matrix: anchor.originFromAnchorTransform)
                entityMap[anchor.id]?.transform.translation = transform.translation + SIMD3<Float>(-0.1, 0.0, 0.1)

                let rotation = simd_quatf(angle: -(.pi / 2), axis: [1, 0, 0])
                entityMap[anchor.id]?.transform.rotation = transform.rotation * rotation
            } else {
                print("inside else")
                sphereEntity.isEnabled = false
            }
        }
}
