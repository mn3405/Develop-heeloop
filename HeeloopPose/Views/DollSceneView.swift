import SceneKit
import SwiftUI

/// SceneKit 뷰 래퍼. 한 손가락 드래그로 회전, 두 손가락으로 확대/이동,
/// 인형의 몸을 탭하면 해당 관절이 선택된다.
struct DollSceneView: UIViewRepresentable {
    let studio: DollStudio

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = studio.scene
        view.allowsCameraControl = true
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = .white
        studio.attach(view: view)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(studio: studio) }

    final class Coordinator: NSObject {
        let studio: DollStudio
        init(studio: DollStudio) { self.studio = studio }

        @MainActor @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? SCNView else { return }
            let point = gesture.location(in: view)
            let hits = view.hitTest(point, options: [
                .searchMode: SCNHitTestSearchMode.closest.rawValue
            ])
            for hit in hits {
                if let name = hit.node.name, name.hasPrefix("joint:"),
                   let joint = Joint(rawValue: String(name.dropFirst("joint:".count))) {
                    studio.selected = joint
                    return
                }
            }
        }
    }
}
