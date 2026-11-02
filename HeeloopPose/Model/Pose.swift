import Foundation

/// 인형의 관절. 캐릭터는 +Z 방향을 보고 서 있고, "L"(왼쪽)은 +X 쪽이다.
/// 모든 뼈는 기본 자세에서 Y축을 따라 뻗어 있다(팔/다리는 아래로 늘어짐).
/// - X 회전: 앞뒤로 굽히기, Y 회전: 비틀기(뼈 축 기준), Z 회전: 옆으로 벌리기
enum Joint: String, CaseIterable, Identifiable {
    case hips, spine, chest, neck, head
    case shoulderL, elbowL, wristL, hipL, kneeL, ankleL
    case shoulderR, elbowR, wristR, hipR, kneeR, ankleR

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hips: return "골반"
        case .spine: return "허리"
        case .chest: return "가슴"
        case .neck: return "목"
        case .head: return "머리"
        case .shoulderL: return "왼어깨"
        case .elbowL: return "왼팔꿈치"
        case .wristL: return "왼손목"
        case .hipL: return "왼고관절"
        case .kneeL: return "왼무릎"
        case .ankleL: return "왼발목"
        case .shoulderR: return "오른어깨"
        case .elbowR: return "오른팔꿈치"
        case .wristR: return "오른손목"
        case .hipR: return "오른고관절"
        case .kneeR: return "오른무릎"
        case .ankleR: return "오른발목"
        }
    }

    /// 왼쪽 +1, 오른쪽 -1, 중심 0
    var side: Float {
        if rawValue.hasSuffix("L") { return 1 }
        if rawValue.hasSuffix("R") { return -1 }
        return 0
    }

    /// 축별 회전 가능 범위(도). 범위가 0...0이면 해당 축은 UI에서 숨긴다.
    var limits: (x: ClosedRange<Float>, y: ClosedRange<Float>, z: ClosedRange<Float>) {
        switch self {
        case .hips: return (-90...90, -180...180, -90...90)
        case .spine, .chest: return (-45...90, -45...45, -30...30)
        case .neck: return (-45...45, -80...80, -40...40)
        case .head: return (-45...45, -70...70, -35...35)
        case .shoulderL: return (-180...60, -90...90, -20...180)
        case .shoulderR: return (-180...60, -90...90, -180...20)
        case .elbowL, .elbowR: return (-150...0, -90...90, 0...0)
        case .wristL, .wristR: return (-80...80, -60...60, -40...40)
        case .hipL: return (-120...40, -60...60, -20...90)
        case .hipR: return (-120...40, -60...60, -90...20)
        case .kneeL, .kneeR: return (0...150, 0...0, 0...0)
        case .ankleL, .ankleR: return (-40...40, -20...20, -20...20)
        }
    }
}

/// 포즈 = 관절별 오일러 각도(도) + 골반 높이 오프셋(키 대비 비율).
struct Pose: Equatable {
    var angles: [Joint: SIMD3<Float>] = [:]
    var rootY: Float = 0
}

struct PosePreset: Identifiable {
    let name: String
    let pose: Pose
    var id: String { name }

    static let all: [PosePreset] = [
        PosePreset(name: "기본", pose: Pose()),
        PosePreset(name: "걷기", pose: Pose(angles: [
            .hipL: SIMD3(-30, 0, 0), .kneeL: SIMD3(10, 0, 0),
            .hipR: SIMD3(20, 0, 0), .kneeR: SIMD3(30, 0, 0),
            .shoulderL: SIMD3(25, 0, 8), .elbowL: SIMD3(-20, 0, 0),
            .shoulderR: SIMD3(-25, 0, -8), .elbowR: SIMD3(-25, 0, 0),
        ])),
        PosePreset(name: "달리기", pose: Pose(angles: [
            .spine: SIMD3(20, 0, 0),
            .hipL: SIMD3(-70, 0, 0), .kneeL: SIMD3(100, 0, 0),
            .hipR: SIMD3(25, 0, 0), .kneeR: SIMD3(20, 0, 0),
            .shoulderL: SIMD3(35, 0, 8), .elbowL: SIMD3(-80, 0, 0),
            .shoulderR: SIMD3(-60, 0, -8), .elbowR: SIMD3(-90, 0, 0),
        ])),
        PosePreset(name: "만세", pose: Pose(angles: [
            .shoulderL: SIMD3(0, 0, 165), .shoulderR: SIMD3(0, 0, -165),
        ])),
        PosePreset(name: "앉기", pose: Pose(angles: [
            .hipL: SIMD3(-90, 0, 0), .hipR: SIMD3(-90, 0, 0),
            .kneeL: SIMD3(90, 0, 0), .kneeR: SIMD3(90, 0, 0),
            .shoulderL: SIMD3(-20, 0, 8), .shoulderR: SIMD3(-20, 0, -8),
        ], rootY: -0.23)),
    ]
}
