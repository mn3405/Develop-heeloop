// HeeloopPose/Model/BodyType.swift 와 같은 값 (키 대비 비율)
export const BODY_TYPES = {
  female: {
    title: '여성', defaultHeight: 1.62, heightRange: [1.4, 1.9],
    base: {
      thigh: 0.235, shin: 0.235, ankleH: 0.04,
      torsoLower: 0.095, torsoUpper: 0.15, chestToNeck: 0.07, neck: 0.045, head: 0.13,
      upperArm: 0.175, foreArm: 0.145, hand: 0.095,
      shoulderHalf: 0.10, hipHalf: 0.052,
      pelvisHalf: 0.092, waistHalf: 0.062, chestHalf: 0.088, chestDepthHalf: 0.055,
      thighR: 0.037, shinR: 0.025, upperArmR: 0.022, foreArmR: 0.018, neckR: 0.021,
      footLen: 0.135, footW: 0.038,
    },
  },
  male: {
    title: '남성', defaultHeight: 1.75, heightRange: [1.5, 2.1],
    base: {
      thigh: 0.24, shin: 0.24, ankleH: 0.04,
      torsoLower: 0.10, torsoUpper: 0.14, chestToNeck: 0.07, neck: 0.045, head: 0.125,
      upperArm: 0.18, foreArm: 0.15, hand: 0.10,
      shoulderHalf: 0.115, hipHalf: 0.05,
      pelvisHalf: 0.085, waistHalf: 0.075, chestHalf: 0.10, chestDepthHalf: 0.06,
      thighR: 0.036, shinR: 0.026, upperArmR: 0.026, foreArmR: 0.021, neckR: 0.026,
      footLen: 0.14, footW: 0.04,
    },
  },
  child: {
    title: '아이', defaultHeight: 1.10, heightRange: [0.7, 1.5],
    base: {
      thigh: 0.205, shin: 0.205, ankleH: 0.04,
      torsoLower: 0.11, torsoUpper: 0.15, chestToNeck: 0.065, neck: 0.035, head: 0.19,
      upperArm: 0.16, foreArm: 0.14, hand: 0.09,
      shoulderHalf: 0.095, hipHalf: 0.045,
      pelvisHalf: 0.07, waistHalf: 0.068, chestHalf: 0.08, chestDepthHalf: 0.058,
      thighR: 0.033, shinR: 0.025, upperArmR: 0.023, foreArmR: 0.019, neckR: 0.022,
      footLen: 0.14, footW: 0.04,
    },
  },
};

export function defaultsFor(type) {
  return {
    bodyType: type,
    height: BODY_TYPES[type].defaultHeight,
    thickness: 1, legScale: 1, torsoScale: 1, armScale: 1, headScale: 1, shoulderScale: 1,
  };
}
