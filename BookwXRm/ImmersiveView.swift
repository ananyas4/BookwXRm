import SwiftUI
import RealityKit
import RealityKitContent
import ARKit
import AVFoundation

struct ImmersiveView: View {
    
    private let session = ARKitSession()
    private let imageTrackingProvider = ImageTrackingProvider(
        referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "PageImages")
    )
    
    @State private var entityMap: [UUID: ModelEntity] = [:]
    @State private var sphereEntity = ModelEntity()
    @State private var skyboxEntity = Entity()
    
    private let SPHERE_MESH: MeshResource = MeshResource.generateSphere(radius: 0.02)
    private let SPHERE_MATERIAL: SimpleMaterial = SimpleMaterial(color: .red, isMetallic: false)
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var currentAudioFile: String?

    var body: some View {
        RealityView { content in
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                // Add skybox content
            }
            
            sphereEntity = ModelEntity(mesh: SPHERE_MESH, materials: [SPHERE_MATERIAL])
            skyboxEntity = createImmersivePicture(imageName: "skybox1.png")
            content.add(skyboxEntity)
            content.add(sphereEntity)
            sphereEntity.isEnabled = false
        }.task {
            await runSession()
            await processImageTrackingUpdates()
        }
    }
    
    func createImmersivePicture(imageName: String) -> Entity {
        let modelEntity = Entity()
        let texture = try? TextureResource.load(named: imageName)
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture!))
        modelEntity.components.set(ModelComponent(mesh: .generateSphere(radius: 1000), materials: [material]))
        modelEntity.scale = .init(x: -1, y: 1, z: 1)
        modelEntity.transform.translation += SIMD3<Float>(0, -0.3, -0.15)
        return modelEntity
    }
    
    func runSession() async {
        do {
            if ImageTrackingProvider.isSupported {
                try await session.run([imageTrackingProvider])
            } else {
                print("Image Tracking Provider is NOT Supported.")
            }
        } catch {
            print("Image Tracking Exception: \(error)")
        }
    }
    
    func processImageTrackingUpdates() async {
        for await update in imageTrackingProvider.anchorUpdates {
            updateImage(update.anchor)
        }
    }
    
    private func updateImage(_ anchor: ImageAnchor) {
        print("updateImage called for image:", anchor.referenceImage.name ?? "Unknown")

        let anchorTransform = Transform(matrix: anchor.originFromAnchorTransform)
        let bookPosition = anchorTransform.translation

        // Check if occlusion box already exists
        if entityMap[anchor.id] == nil {
            print(" creating occlusion box at detected position \(anchor) " )
            

            let bookSize = SIMD3<Float>(
                0.55,  // Convert CGFloat → Float
                0.35,  // Approximate depth
                0.25 // Convert CGFloat → Float
            )

            let occlusionBox = createOcclusionBox(size: bookSize, position: bookPosition)
            entityMap[anchor.id] = occlusionBox
            skyboxEntity.addChild(occlusionBox)
        } else {
            entityMap[anchor.id]!.transform.translation = anchorTransform.translation
        }

        // **🔹 Page Detection Logic (Re-Added)**
        if anchor.isTracked {
            let imageName = anchor.referenceImage.name ?? "Unknown"
            print("Detected Image Name: \(imageName)")

            if imageName.contains("page12") {
                print("✅ Page 12 detected!")
                updateSkybox(imageName: "skybox1.png")
                playAudio(filename: "realityhack.mp3")  // Play audio when page 12 is detected
            }
            else if imageName.contains("page34") {
                print("✅ Page 34 detected!")
                updateSkybox(imageName: "skybox2.png")
                // No new audio → keeps playing "realityhack.mp3" if no new audio is specified
            }
        } else {
            print("⏳ Anchor lost tracking, keeping occlusion box for a few seconds.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                
            }
        }
    }

    func createOcclusionBox(size: SIMD3<Float>, position: SIMD3<Float>) -> ModelEntity {
        let boxMesh = MeshResource.generateBox(size: size)
        let occlusionMaterial = OcclusionMaterial()
        let occlusionEntity = ModelEntity(mesh: boxMesh, materials: [occlusionMaterial])

        occlusionEntity.transform.translation = position
        return occlusionEntity
    }

    private func updateSkybox(imageName: String) {
        let texture = try? TextureResource.load(named: imageName)
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture!))
        skyboxEntity.components.set(ModelComponent(mesh: .generateSphere(radius: 1000), materials: [material]))
    }
    
    private func playAudio(filename: String) {
        // Prevent reloading if the same audio is already playing
        if currentAudioFile == filename {
            return
        }

        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            print("❌ Audio file not found: \(filename)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.play()
            currentAudioFile = filename
        } catch {
            print("❌ Error playing audio: \(error)")
        }
    }
}
