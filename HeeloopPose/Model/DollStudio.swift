import SceneKit
import SwiftUI
import Metal

enum CameraPreset: String, CaseIterable, Identifiable {
    case front, threeQuarter, left, back, right

    var id: String { rawValue }

    var title: String {
        switch self {
        case .front: return "정면"
        case .threeQuarter: return "3/4"
        case .left: return "왼쪽"
        case .back: return "뒷면"
        case .right: return "오른쪽"
        }
    }

    /// 인형은 +Z를 바라보고, 왼쪽은 +X.
    var direction: SIMD3<Float> {
        switch self {
        case .front: return SIMD3(0, 0.08, 1)
        case .threeQuarter: return SIMD3(0.7, 0.15, 0.7)
        case .left: return SIMD3(1, 0.08, 0)
        case .back: return SIMD3(0, 0.08, -1)
        case .right: return SIMD3(-1, 0.08, 0)
        }
    }
}

/// 씬, 인형, 카메라, 캡처를 관리하는 중심 객체.
@MainActor
final class DollStudio: ObservableObject {
    @Published var params: DollParameters {
        didSet { if params != oldValue { rebuild() } }
    }
    @Published var pose = Pose() {
        didSet { rig?.apply(pose) }
    }
    @Published var selected: Joint = .shoulderL {
        didSet { rig?.highlight(selected) }
    }

    let scene = SCNScene()
    let cameraNode = SCNNode()
    private let stage = SCNNode()
    private var rig: DollRig?
    private weak var scnView: SCNView?

    init() {
        params = .defaults(for: .male)
        setupScene()
        rebuild()
        moveCamera(.front, animated: false)
    }

    func attach(view: SCNView) {
        scnView = view
        view.pointOfView = cameraNode
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.defaultCameraController.target = target
    }

    func setBodyType(_ type: BodyType) {
        params = .defaults(for: type)
        moveCamera(.front, animated: true)
    }

    func resetPose() {
        pose = Pose()
    }

    // MARK: - Camera

    private var target: SCNVector3 { SCNVector3(0, params.height * 0.5, 0) }

    func moveCamera(_ preset: CameraPreset, animated: Bool = true) {
        let t = target
        let d = params.height * 2.3
        let dir = simd_normalize(preset.direction)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = animated ? 0.35 : 0
        cameraNode.position = SCNVector3(t.x + dir.x * d, t.y + dir.y * d, t.z + dir.z * d)
        cameraNode.look(at: t)
        SCNTransaction.commit()
        scnView?.defaultCameraController.target = t
    }

    // MARK: - Capture

    /// 선택 하이라이트와 바닥 원판을 숨기고 고해상도로 렌더링한다.
    func captureImage() -> UIImage? {
        guard let view = scnView else { return nil }
        rig?.highlight(nil)
        stage.isHidden = true
        defer {
            rig?.highlight(selected)
            stage.isHidden = false
        }
        let aspect = view.bounds.height > 0 ? view.bounds.width / view.bounds.height : 0.75
        let size = CGSize(width: 1600, height: 1600 / aspect)
        if let device = MTLCreateSystemDefaultDevice() {
            let renderer = SCNRenderer(device: device, options: nil)
            renderer.scene = scene
            renderer.pointOfView = view.pointOfView ?? cameraNode
            return renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
        }
        return view.snapshot()
    }

    // MARK: - Scene

    private func setupScene() {
        scene.background.contents = UIColor.white

        let camera = SCNCamera()
        camera.fieldOfView = 35
        camera.zNear = 0.05
        camera.zFar = 50
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 650
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 900
        key.eulerAngles = SCNVector3(-0.7, 0.6, 0)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 350
        fill.eulerAngles = SCNVector3(-0.3, -2.4, 0)
        scene.rootNode.addChildNode(fill)

        // 바닥 원판 (방향 감각용, 캡처에서는 숨김)
        let disk = SCNCylinder(radius: 0.6, height: 0.004)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(white: 0.9, alpha: 1)
        disk.materials = [mat]
        stage.geometry = disk
        stage.position = SCNVector3(0, -0.002, 0)
        scene.rootNode.addChildNode(stage)
    }

    private func rebuild() {
        rig?.root.removeFromParentNode()
        let newRig = DollRig(params: params)
        scene.rootNode.addChildNode(newRig.root)
        newRig.apply(pose)
        newRig.highlight(selected)
        rig = newRig
        scnView?.defaultCameraController.target = target
    }
}
