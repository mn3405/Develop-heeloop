// HeeloopPose/Model/Pose.swift 와 같은 값
// 캐릭터는 +Z를 보고, L(왼쪽)은 +X. 모든 뼈는 기본 자세에서 Y축을 따라 뻗는다.
// X: 앞뒤 굽히기, Y: 비틀기, Z: 옆으로 벌리기
export const JOINTS = [
  'hips', 'spine', 'chest', 'neck', 'head',
  'shoulderL', 'elbowL', 'wristL', 'hipL', 'kneeL', 'ankleL',
  'shoulderR', 'elbowR', 'wristR', 'hipR', 'kneeR', 'ankleR',
];

export const JOINT_INFO = {
  hips: { title: '골반', limits: [[-90, 90], [-180, 180], [-90, 90]] },
  spine: { title: '허리', limits: [[-45, 90], [-45, 45], [-30, 30]] },
  chest: { title: '가슴', limits: [[-45, 90], [-45, 45], [-30, 30]] },
  neck: { title: '목', limits: [[-45, 45], [-80, 80], [-40, 40]] },
  head: { title: '머리', limits: [[-45, 45], [-70, 70], [-35, 35]] },
  shoulderL: { title: '왼어깨', limits: [[-180, 60], [-90, 90], [-20, 180]] },
  elbowL: { title: '왼팔꿈치', limits: [[-150, 0], [-90, 90], [0, 0]] },
  wristL: { title: '왼손목', limits: [[-80, 80], [-60, 60], [-40, 40]] },
  hipL: { title: '왼고관절', limits: [[-120, 40], [-60, 60], [-20, 90]] },
  kneeL: { title: '왼무릎', limits: [[0, 150], [0, 0], [0, 0]] },
  ankleL: { title: '왼발목', limits: [[-40, 40], [-20, 20], [-20, 20]] },
  shoulderR: { title: '오른어깨', limits: [[-180, 60], [-90, 90], [-180, 20]] },
  elbowR: { title: '오른팔꿈치', limits: [[-150, 0], [-90, 90], [0, 0]] },
  wristR: { title: '오른손목', limits: [[-80, 80], [-60, 60], [-40, 40]] },
  hipR: { title: '오른고관절', limits: [[-120, 40], [-60, 60], [-90, 20]] },
  kneeR: { title: '오른무릎', limits: [[0, 150], [0, 0], [0, 0]] },
  ankleR: { title: '오른발목', limits: [[-40, 40], [-20, 20], [-20, 20]] },
};

export const sideOf = (j) => (j.endsWith('L') ? 1 : j.endsWith('R') ? -1 : 0);

export const PRESETS = [
  { name: '기본', angles: {}, rootY: 0 },
  {
    name: '걷기', rootY: 0, angles: {
      hipL: [-30, 0, 0], kneeL: [10, 0, 0], hipR: [20, 0, 0], kneeR: [30, 0, 0],
      shoulderL: [25, 0, 8], elbowL: [-20, 0, 0], shoulderR: [-25, 0, -8], elbowR: [-25, 0, 0],
    },
  },
  {
    name: '달리기', rootY: 0, angles: {
      spine: [20, 0, 0],
      hipL: [-70, 0, 0], kneeL: [100, 0, 0], hipR: [25, 0, 0], kneeR: [20, 0, 0],
      shoulderL: [35, 0, 8], elbowL: [-80, 0, 0], shoulderR: [-60, 0, -8], elbowR: [-90, 0, 0],
    },
  },
  { name: '만세', rootY: 0, angles: { shoulderL: [0, 0, 165], shoulderR: [0, 0, -165] } },
  {
    name: '앉기', rootY: -0.23, angles: {
      hipL: [-90, 0, 0], hipR: [-90, 0, 0], kneeL: [90, 0, 0], kneeR: [90, 0, 0],
      shoulderL: [-20, 0, 8], shoulderR: [-20, 0, -8],
    },
  },
];

export const CAMERA_PRESETS = [
  { name: '정면', dir: [0, 0.08, 1] },
  { name: '3/4', dir: [0.7, 0.15, 0.7] },
  { name: '왼쪽', dir: [1, 0.08, 0] },
  { name: '뒷면', dir: [0, 0.08, -1] },
  { name: '오른쪽', dir: [-1, 0.08, 0] },
];
