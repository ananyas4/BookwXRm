import SwiftUI
import RealityKit
import RealityKitContent
import ARKit
import AVFoundation
import WebKit

struct ImmersiveView: View {
    
    
    private let session = ARKitSession()
    private let imageTrackingProvider = ImageTrackingProvider(
        referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "PageImages")
    )
    
    @State private var entityMap: [UUID: ModelEntity] = [:]
    @State private var sphereEntity = ModelEntity()
    @State private var skyboxEntity = Entity()
    @State private var youtubeEntity = Entity()

    
    @State private var showYouTubeVideo = false // 🔹 State to show/hide YouTube video
    
    private let SPHERE_MESH: MeshResource = MeshResource.generateSphere(radius: 0.02)
    private let SPHERE_MATERIAL: SimpleMaterial = SimpleMaterial(color: .red, isMetallic: false)
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var currentAudioFile: String?

    var body: some View {
    
        ZStack {
            
            RealityView { content, attachments in
                if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    // Add skybox content
                }
                
                sphereEntity = ModelEntity(mesh: SPHERE_MESH, materials: [SPHERE_MATERIAL])
                skyboxEntity = createImmersivePicture(imageName: "skybox1.png")
                content.add(skyboxEntity)
                content.add(sphereEntity)
                sphereEntity.isEnabled = false
                
                let bookSize = SIMD3<Float>(
                    0.55,
                    0.35,
                    0.25
                )
                
                let bookPosition = SIMD3<Float>(0, 1.4, -0.2)
                
                let occlusionBox = createOcclusionBox(size: bookSize, position: bookPosition)
                skyboxEntity.addChild(occlusionBox)
                
                if let youtubePanel = attachments.entity(for: "Youtube" ){
                    
                    youtubePanel.position = [0, 1.7, -1]
                    content.add(youtubePanel)
                    youtubeEntity = youtubePanel
                    youtubeEntity.isEnabled = showYouTubeVideo
                    
                }
            } attachments: {
                Attachment(id: "Youtube" ) {
                    youtubePanel()
                }
            }.task {
                await runSession()
                await processImageTrackingUpdates()
            }.onChange(of: showYouTubeVideo){
                
                    youtubeEntity.isEnabled = $1
                
            }
            
            // 🔹 Show YouTube video when page 23 is detected
            
        }
    }
    
    func youtubePanel() -> some View {
        
        VStack {
            Text("Watch this Video!")
                .font(.title)
                .foregroundColor(.white)
            
            YouTubeWebView(videoID: "R2lP146KA5A") // Replace with the correct video ID
                .frame(width: 600, height: 400)
                .cornerRadius(12)
                .shadow(radius: 10)
                
            Button("Close Video") {
                showYouTubeVideo = false // Hide when user clicks
            }
            .padding()
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(10)
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .padding()
        

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
        if showYouTubeVideo {
            print("showYoutubeVideo triggered")
        }
        print("updateImage called for image:", anchor.referenceImage.name ?? "Unknown")

        let anchorTransform = Transform(matrix: anchor.originFromAnchorTransform)
        let bookPosition = anchorTransform.translation

        // Check if occlusion box already exists
        if entityMap[anchor.id] == nil {
            print("Creating occlusion box at detected position \(anchor)")

            let bookSize = SIMD3<Float>(
                0.55,
                0.35,
                0.25
            )

            let occlusionBox = createOcclusionBox(size: bookSize, position: bookPosition)
            entityMap[anchor.id] = occlusionBox
            skyboxEntity.addChild(occlusionBox)
        } else {
            entityMap[anchor.id]!.transform.translation = anchorTransform.translation
        }

        // **🔹 Page Detection Logic**
        if anchor.isTracked {
            let imageName = anchor.referenceImage.name ?? "Unknown"
            print("Detected Image Name: \(imageName)")

            if imageName.contains("page12") {
                print("✅ Page 12 detected!")
                updateSkybox(imageName: "skybox1.png")
                playAudio(filename: "realityhack.mp3")
            }
            else if imageName.contains("page34") {
                print("✅ Page 34 detected!")
                updateSkybox(imageName: "skybox2.png")
                
                playAudio(filename: "realityhack_secondtrack.mp3")
                showYouTubeVideo = true // Show the video overlay

            }
          
        } else {
            print("⏳ Anchor lost tracking, keeping occlusion box for a few seconds.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { }
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
        if currentAudioFile == filename {
            return
        }

        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            print("❌ Audio file not found: \(filename)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
            currentAudioFile = filename
        } catch {
            print("❌ Error playing audio: \(error)")
        }
    }
}

// 🔹 YouTube Video WebView using WKWebView
struct YouTubeWebView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.configuration.allowsInlineMediaPlayback = true
        webView.scrollView.isScrollEnabled = false

        let embedURL = "https://www.youtube.com/embed/\(videoID)?playsinline=1&autoplay=1"
        if let url = URL(string: embedURL) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
