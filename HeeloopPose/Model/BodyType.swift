import Foundation

/// 모든 길이는 "키(H) 대비 비율"이다. 합산하면 1.0이 되도록 맞춰져 있다.
struct BaseProportions {
    // 길이
    var thigh: Float, shin: Float, ankleH: Float
    var torsoLower: Float, torsoUpper: Float, chestToNeck: Float
    var neck: Float, head: Float
    var upperArm: Float, foreArm: Float, hand: Float
    // 폭 (절반 값)
    var shoulderHalf: Float, hipHalf: Float
    var pelvisHalf: Float, waistHalf: Float, chestHalf: Float, chestDepthHalf: Float
    // 반지름
    var thighR: Float, shinR: Float, upperArmR: Float, foreArmR: Float, neckR: Float
    // 발
    var footLen: Float, footW: Float
}

enum BodyType: String, CaseIterable, Identifiable {
    case female, male, child

    var id: String { rawValue }

    var title: String {
        switch self {
        case .female: return "여성"
        case .male: return "남성"
        case .child: return "아이"
        }
    }

    var defaultHeight: Float {
        switch self {
        case .female: return 1.62
        case .male: return 1.75
        case .child: return 1.10
        }
    }

    var heightRange: ClosedRange<Float> {
        switch self {
        case .female: return 1.40...1.90
        case .male: return 1.50...2.10
        case .child: return 0.70...1.50
        }
    }

    var base: BaseProportions {
        switch self {
        case .male:
            return BaseProportions(
                thigh: 0.24, shin: 0.24, ankleH: 0.04,
                torsoLower: 0.10, torsoUpper: 0.14, chestToNeck: 0.07,
                neck: 0.045, head: 0.125,
                upperArm: 0.18, foreArm: 0.15, hand: 0.10,
                shoulderHalf: 0.115, hipHalf: 0.05,
                pelvisHalf: 0.085, waistHalf: 0.075, chestHalf: 0.10, chestDepthHalf: 0.06,
                thighR: 0.036, shinR: 0.026, upperArmR: 0.026, foreArmR: 0.021, neckR: 0.026,
                footLen: 0.14, footW: 0.04)
        case .female:
            return BaseProportions(
                thigh: 0.235, shin: 0.235, ankleH: 0.04,
                torsoLower: 0.095, torsoUpper: 0.15, chestToNeck: 0.07,
                neck: 0.045, head: 0.13,
                upperArm: 0.175, foreArm: 0.145, hand: 0.095,
                shoulderHalf: 0.10, hipHalf: 0.052,
                pelvisHalf: 0.092, waistHalf: 0.062, chestHalf: 0.088, chestDepthHalf: 0.055,
                thighR: 0.037, shinR: 0.025, upperArmR: 0.022, foreArmR: 0.018, neckR: 0.021,
                footLen: 0.135, footW: 0.038)
        case .child:
            return BaseProportions(
                thigh: 0.205, shin: 0.205, ankleH: 0.04,
                torsoLower: 0.11, torsoUpper: 0.15, chestToNeck: 0.065,
                neck: 0.035, head: 0.19,
                upperArm: 0.16, foreArm: 0.14, hand: 0.09,
                shoulderHalf: 0.095, hipHalf: 0.045,
                pelvisHalf: 0.07, waistHalf: 0.068, chestHalf: 0.08, chestDepthHalf: 0.058,
                thighR: 0.033, shinR: 0.025, upperArmR: 0.023, foreArmR: 0.019, neckR: 0.022,
                footLen: 0.14, footW: 0.04)
        }
    }
}

/// 사용자가 슬라이더로 조절하는 값들.
struct DollParameters: Equatable {
    var bodyType: BodyType
    var height: Float            // 미터
    var thickness: Float = 1.0   // 체형 굵기 (0.6 얇게 ~ 1.6 두껍게)
    var legScale: Float = 1.0    // 다리 길이
    var torsoScale: Float = 1.0  // 몸통 길이
    var armScale: Float = 1.0    // 팔 길이
    var headScale: Float = 1.0   // 머리 크기
    var shoulderScale: Float = 1.0 // 어깨/가슴 너비

    static func defaults(for type: BodyType) -> DollParameters {
        DollParameters(bodyType: type, height: type.defaultHeight)
    }
}
