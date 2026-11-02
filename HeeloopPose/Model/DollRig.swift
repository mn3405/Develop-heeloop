import SceneKit
import UIKit

/// 파라미터로부터 관절 계층(뼈대)과 마네킹 외형을 코드로 만든다.
/// 나중에 USDZ 같은 외부 모델로 교체하려면 이 클래스와 같은 인터페이스
/// (`root`, `apply(_:)`, `highlight(_:)`)만 구현하면 된다.
final class DollRig {
    let root = SCNNode()
    private(set) var joints: [Joint: SCNNode] = [:]
    private var visuals: [Joint: [SCNNode]] = [:]
    private let params: DollParameters
    private let restHipsY: Float

    private static let bodyColor = UIColor(red: 0.87, green: 0.76, blue: 0.62, alpha: 1)
    private static let jointColor = UIColor(red: 0.55, green: 0.42, blue: 0.30, alpha: 1)
    private static let highlightColor = UIColor(red: 0.95, green: 0.38, blue: 0.0, alpha: 1)

    init(params: DollParameters) {
        self.params = params
        let b = params.bodyType.base
        restHipsY = params.height * (b.ankleH + (b.shin + b.thigh) * params.legScale)
        build()
    }

    // MARK: - Public

    func apply(_ pose: Pose) {
        let k = Float.pi / 180
        for (joint, node) in joints {
            let a = pose.angles[joint] ?? .zero
            node.eulerAngles = SCNVector3(a.x * k, a.y * k, a.z * k)
        }
        joints[.hips]?.position.y = restHipsY + pose.rootY * params.height
    }

    func highlight(_ joint: Joint?) {
        for (j, nodes) in visuals {
            let on = (j == joint)
            for node in nodes {
                node.geometry?.firstMaterial?.emission.contents = on ? DollRig.highlightColor : UIColor.black
            }
        }
    }

    // MARK: - Build

    private func build() {
        let p = params
        let b = p.bodyType.base
        let H = p.height
        let t = p.thickness
        func L(_ f: Float) -> Float { f * H }

        let thigh = L(b.thigh) * p.legScale
        let shin = L(b.shin) * p.legScale
        let ankleH = L(b.ankleH)
        let torsoLower = L(b.torsoLower) * p.torsoScale
        let torsoUpper = L(b.torsoUpper) * p.torsoScale
        let chestToNeck = L(b.chestToNeck) * p.torsoScale
        let neckLen = L(b.neck)
        let headH = L(b.head) * p.headScale
        let upperArm = L(b.upperArm) * p.armScale
        let foreArm = L(b.foreArm) * p.armScale
        let handLen = L(b.hand) * p.armScale
        let shoulderHalf = L(b.shoulderHalf) * p.shoulderScale
        let chestHalf = L(b.chestHalf) * p.shoulderScale
        let hipHalf = L(b.hipHalf)
        let depthHalf = L(b.chestDepthHalf)

        // 몸통
        let hips = makeJoint(.hips, parent: root, at: SCNVector3(0, restHipsY, 0))
        addVisual(box(L(b.pelvisHalf) * 2 * t, torsoLower, depthHalf * 1.9 * t),
                  joint: .hips, to: hips, at: SCNVector3(0, torsoLower * 0.35, 0))

        let spine = makeJoint(.spine, parent: hips, at: SCNVector3(0, torsoLower, 0))
        addVisual(capsule(L(b.waistHalf) * t, torsoLower + torsoUpper),
                  joint: .spine, to: spine,
                  at: SCNVector3(0, (torsoUpper - torsoLower) / 2, 0),
                  scale: SCNVector3(1, 1, 0.8))

        let chest = makeJoint(.chest, parent: spine, at: SCNVector3(0, torsoUpper, 0))
        let chestH = chestToNeck * 0.9 + torsoUpper * 0.45
        addVisual(box(chestHalf * 2 * t, chestH, depthHalf * 2 * t),
                  joint: .chest, to: chest,
                  at: SCNVector3(0, (chestToNeck * 0.9 - torsoUpper * 0.45) / 2, 0))

        let neck = makeJoint(.neck, parent: chest, at: SCNVector3(0, chestToNeck, 0))
        addVisual(capsule(L(b.neckR) * t, neckLen),
                  joint: .neck, to: neck, at: SCNVector3(0, neckLen / 2, 0))

        let head = makeJoint(.head, parent: neck, at: SCNVector3(0, neckLen, 0))
        addVisual(SCNSphere(radius: CGFloat(headH / 2)),
                  joint: .head, to: head, at: SCNVector3(0, headH * 0.5, 0),
                  scale: SCNVector3(0.82, 1, 0.92))

        // 팔
        let armJoints: [(Joint, Joint, Joint)] = [(.shoulderL, .elbowL, .wristL), (.shoulderR, .elbowR, .wristR)]
        for (sJ, eJ, wJ) in armJoints {
            let s = sJ.side
            let shoulder = makeJoint(sJ, parent: chest, at: SCNVector3(s * shoulderHalf, chestToNeck * 0.85, 0))
            let r1 = L(b.upperArmR) * t
            addVisual(SCNSphere(radius: CGFloat(r1 * 1.25)), joint: sJ, to: shoulder, at: SCNVector3Zero, color: DollRig.jointColor)
            addVisual(capsule(r1, upperArm), joint: sJ, to: shoulder, at: SCNVector3(0, -upperArm / 2, 0))

            let elbow = makeJoint(eJ, parent: shoulder, at: SCNVector3(0, -upperArm, 0))
            let r2 = L(b.foreArmR) * t
            addVisual(SCNSphere(radius: CGFloat(r2 * 1.2)), joint: eJ, to: elbow, at: SCNVector3Zero, color: DollRig.jointColor)
            addVisual(capsule(r2, foreArm), joint: eJ, to: elbow, at: SCNVector3(0, -foreArm / 2, 0))

            let wrist = makeJoint(wJ, parent: elbow, at: SCNVector3(0, -foreArm, 0))
            addVisual(SCNSphere(radius: CGFloat(r2 * 0.95)), joint: wJ, to: wrist, at: SCNVector3Zero, color: DollRig.jointColor)
            addVisual(capsule(r2 * 0.9, handLen), joint: wJ, to: wrist,
                      at: SCNVector3(0, -handLen / 2, 0), scale: SCNVector3(1, 1, 0.55))
        }

        // 다리
        let legJoints: [(Joint, Joint, Joint)] = [(.hipL, .kneeL, .ankleL), (.hipR, .kneeR, .ankleR)]
        for (hJ, kJ, aJ) in legJoints {
            let s = hJ.side
            let hip = makeJoint(hJ, parent: hips, at: SCNVector3(s * hipHalf, 0, 0))
            let r1 = L(b.thighR) * t
            addVisual(SCNSphere(radius: CGFloat(r1 * 1.1)), joint: hJ, to: hip, at: SCNVector3Zero, color: DollRig.jointColor)
            addVisual(capsule(r1, thigh), joint: hJ, to: hip, at: SCNVector3(0, -thigh / 2, 0))

            let knee = makeJoint(kJ, parent: hip, at: SCNVector3(0, -thigh, 0))
            let r2 = L(b.shinR) * t
            addVisual(SCNSphere(radius: CGFloat(r2 * 1.15)), joint: kJ, to: knee, at: SCNVector3Zero, color: DollRig.jointColor)
            addVisual(capsule(r2, shin), joint: kJ, to: knee, at: SCNVector3(0, -shin / 2, 0))

            let ankle = makeJoint(aJ, parent: knee, at: SCNVector3(0, -shin, 0))
            addVisual(SCNSphere(radius: CGFloat(r2 * 0.9)), joint: aJ, to: ankle, at: SCNVector3Zero, color: DollRig.jointColor)
            let footLen = L(b.footLen)
            addVisual(box(L(b.footW) * t, ankleH, footLen),
                      joint: aJ, to: ankle, at: SCNVector3(0, -ankleH / 2, footLen * 0.25))
        }
    }

    // MARK: - Helpers

    private func makeJoint(_ joint: Joint, parent: SCNNode, at position: SCNVector3) -> SCNNode {
        let node = SCNNode()
        node.name = "rig:\(joint.rawValue)"
        node.position = position
        parent.addChildNode(node)
        joints[joint] = node
        return node
    }

    private func capsule(_ radius: Float, _ length: Float) -> SCNCapsule {
        SCNCapsule(capRadius: CGFloat(radius), height: CGFloat(max(length + radius, radius * 2 + 0.001)))
    }

    private func box(_ w: Float, _ h: Float, _ l: Float) -> SCNBox {
        let chamfer = CGFloat(min(w, h, l) * 0.4)
        return SCNBox(width: CGFloat(w), height: CGFloat(h), length: CGFloat(l), chamferRadius: chamfer)
    }

    private func addVisual(_ geometry: SCNGeometry, joint: Joint, to node: SCNNode,
                           at position: SCNVector3, scale: SCNVector3 = SCNVector3(1, 1, 1),
                           color: UIColor = DollRig.bodyColor) {
        let material = SCNMaterial()
        material.lightingModel = .blinn
        material.diffuse.contents = color
        material.specular.contents = UIColor(white: 0.25, alpha: 1)
        geometry.materials = [material]

        let visual = SCNNode(geometry: geometry)
        visual.position = position
        visual.scale = scale
        // 화면에서 탭했을 때 어느 관절인지 알아내기 위한 이름표
        visual.name = "joint:\(joint.rawValue)"
        node.addChildNode(visual)
        visuals[joint, default: []].append(visual)
    }
}
