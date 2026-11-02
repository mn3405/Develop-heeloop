import SwiftUI

struct ContentView: View {
    @StateObject private var studio = DollStudio()
    @State private var tab: Tab = .joint
    @State private var message: String?

    enum Tab: String, CaseIterable, Identifiable {
        case joint = "관절", body = "체형", preset = "포즈"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                DollSceneView(studio: studio)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: capture) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.orange)
                                .background(Circle().fill(.white))
                        }
                        .padding()
                    }
                    Spacer()
                    cameraBar
                }
            }

            Picker("탭", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                switch tab {
                case .joint: JointPanel(studio: studio)
                case .body: BodyPanel(studio: studio)
                case .preset: PosePanel(studio: studio)
                }
            }
            .frame(height: 210, alignment: .top)
            .padding(.bottom)
        }
        .overlay(alignment: .top) {
            if let message {
                Text(message)
                    .font(.footnote)
                    .padding(10)
                    .background(.ultraThickMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
        .animation(.default, value: message)
    }

    private var cameraBar: some View {
        HStack(spacing: 6) {
            ForEach(CameraPreset.allCases) { preset in
                Button(preset.title) { studio.moveCamera(preset) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.bottom, 8)
    }

    private func capture() {
        guard let image = studio.captureImage() else {
            show("캡처에 실패했어요")
            return
        }
        Task {
            do {
                try await PhotoAlbumSaver.save(image: image)
                show("'\(PhotoAlbumSaver.albumTitle)' 앨범에 저장했어요")
            } catch {
                show(error.localizedDescription)
            }
        }
    }

    private func show(_ text: String) {
        message = text
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if message == text { message = nil }
        }
    }
}
