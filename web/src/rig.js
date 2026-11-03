import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/examples/jsm/geometries/RoundedBoxGeometry.js';
import { BODY_TYPES } from './bodytype.js';
import { sideOf } from './pose.js';

const BODY_COLOR = 0xdec29e;
const JOINT_COLOR = 0x8c6b4d;
const HIGHLIGHT = 0xf26100;

// HeeloopPose/Model/DollRig.swift 의 build()를 그대로 옮긴 것
export function buildRig(params) {
  const b = BODY_TYPES[params.bodyType].base;
  const H = params.height;
  const t = params.thickness;
  const L = (f) => f * H;

  const root = new THREE.Group();
  const joints = {};
  const visuals = {};

  const restHipsY = H * (b.ankleH + (b.shin + b.thigh) * params.legScale);

  function makeJoint(name, parent, x, y, z) {
    const g = new THREE.Group();
    g.position.set(x, y, z);
    g.rotation.order = 'XYZ'; // SceneKit eulerAngles 와 같은 합성 순서
    parent.add(g);
    joints[name] = g;
    return g;
  }

  function capsule(r, length) {
    const height = Math.max(length + r, r * 2 + 0.001);
    return new THREE.CapsuleGeometry(r, height - r * 2, 8, 24);
  }

  function box(w, h, l) {
    return new RoundedBoxGeometry(w, h, l, 4, Math.min(w, h, l) * 0.4);
  }

  function addVisual(geometry, joint, node, pos, scale = [1, 1, 1], color = BODY_COLOR) {
    const mat = new THREE.MeshStandardMaterial({ color, roughness: 0.55, metalness: 0.0 });
    const mesh = new THREE.Mesh(geometry, mat);
    mesh.position.set(pos[0], pos[1], pos[2]);
    mesh.scale.set(scale[0], scale[1], scale[2]);
    mesh.userData.joint = joint;
    node.add(mesh);
    (visuals[joint] ||= []).push(mesh);
  }

  const sphere = (r) => new THREE.SphereGeometry(r, 24, 16);

  const thigh = L(b.thigh) * params.legScale;
  const shin = L(b.shin) * params.legScale;
  const ankleH = L(b.ankleH);
  const torsoLower = L(b.torsoLower) * params.torsoScale;
  const torsoUpper = L(b.torsoUpper) * params.torsoScale;
  const chestToNeck = L(b.chestToNeck) * params.torsoScale;
  const neckLen = L(b.neck);
  const headH = L(b.head) * params.headScale;
  const upperArm = L(b.upperArm) * params.armScale;
  const foreArm = L(b.foreArm) * params.armScale;
  const handLen = L(b.hand) * params.armScale;
  const shoulderHalf = L(b.shoulderHalf) * params.shoulderScale;
  const chestHalf = L(b.chestHalf) * params.shoulderScale;
  const hipHalf = L(b.hipHalf);
  const depthHalf = L(b.chestDepthHalf);

  // 몸통
  const hips = makeJoint('hips', root, 0, restHipsY, 0);
  addVisual(box(L(b.pelvisHalf) * 2 * t, torsoLower, depthHalf * 1.9 * t), 'hips', hips, [0, torsoLower * 0.35, 0]);

  const spine = makeJoint('spine', hips, 0, torsoLower, 0);
  addVisual(capsule(L(b.waistHalf) * t, torsoLower + torsoUpper), 'spine', spine,
    [0, (torsoUpper - torsoLower) / 2, 0], [1, 1, 0.8]);

  const chest = makeJoint('chest', spine, 0, torsoUpper, 0);
  const chestH = chestToNeck * 0.9 + torsoUpper * 0.45;
  addVisual(box(chestHalf * 2 * t, chestH, depthHalf * 2 * t), 'chest', chest,
    [0, (chestToNeck * 0.9 - torsoUpper * 0.45) / 2, 0]);

  const neck = makeJoint('neck', chest, 0, chestToNeck, 0);
  addVisual(capsule(L(b.neckR) * t, neckLen), 'neck', neck, [0, neckLen / 2, 0]);

  const head = makeJoint('head', neck, 0, neckLen, 0);
  addVisual(sphere(headH / 2), 'head', head, [0, headH * 0.5, 0], [0.82, 1, 0.92]);

  // 팔
  for (const [sJ, eJ, wJ] of [['shoulderL', 'elbowL', 'wristL'], ['shoulderR', 'elbowR', 'wristR']]) {
    const s = sideOf(sJ);
    const shoulder = makeJoint(sJ, chest, s * shoulderHalf, chestToNeck * 0.85, 0);
    const r1 = L(b.upperArmR) * t;
    addVisual(sphere(r1 * 1.25), sJ, shoulder, [0, 0, 0], [1, 1, 1], JOINT_COLOR);
    addVisual(capsule(r1, upperArm), sJ, shoulder, [0, -upperArm / 2, 0]);

    const elbow = makeJoint(eJ, shoulder, 0, -upperArm, 0);
    const r2 = L(b.foreArmR) * t;
    addVisual(sphere(r2 * 1.2), eJ, elbow, [0, 0, 0], [1, 1, 1], JOINT_COLOR);
    addVisual(capsule(r2, foreArm), eJ, elbow, [0, -foreArm / 2, 0]);

    const wrist = makeJoint(wJ, elbow, 0, -foreArm, 0);
    addVisual(sphere(r2 * 0.95), wJ, wrist, [0, 0, 0], [1, 1, 1], JOINT_COLOR);
    addVisual(capsule(r2 * 0.9, handLen), wJ, wrist, [0, -handLen / 2, 0], [1, 1, 0.55]);
  }

  // 다리
  for (const [hJ, kJ, aJ] of [['hipL', 'kneeL', 'ankleL'], ['hipR', 'kneeR', 'ankleR']]) {
    const s = sideOf(hJ);
    const hip = makeJoint(hJ, hips, s * hipHalf, 0, 0);
    const r1 = L(b.thighR) * t;
    addVisual(sphere(r1 * 1.1), hJ, hip, [0, 0, 0], [1, 1, 1], JOINT_COLOR);
    addVisual(capsule(r1, thigh), hJ, hip, [0, -thigh / 2, 0]);

    const knee = makeJoint(kJ, hip, 0, -thigh, 0);
    const r2 = L(b.shinR) * t;
    addVisual(sphere(r2 * 1.15), kJ, knee, [0, 0, 0], [1, 1, 1], JOINT_COLOR);
    addVisual(capsule(r2, shin), kJ, knee, [0, -shin / 2, 0]);

    const ankle = makeJoint(aJ, knee, 0, -shin, 0);
    addVisual(sphere(r2 * 0.9), aJ, ankle, [0, 0, 0], [1, 1, 1], JOINT_COLOR);
    const footLen = L(b.footLen);
    addVisual(box(L(b.footW) * t, ankleH, footLen), aJ, ankle, [0, -ankleH / 2, footLen * 0.25]);
  }

  const k = Math.PI / 180;
  return {
    root,
    joints,
    visuals,
    meshes: Object.values(visuals).flat(),
    apply(pose) {
      for (const [name, node] of Object.entries(joints)) {
        const a = pose.angles[name] || [0, 0, 0];
        node.rotation.set(a[0] * k, a[1] * k, a[2] * k, 'XYZ');
      }
      joints.hips.position.y = restHipsY + pose.rootY * H;
    },
    highlight(joint) {
      for (const [name, meshes] of Object.entries(visuals)) {
        for (const m of meshes) m.material.emissive.setHex(name === joint ? HIGHLIGHT : 0x000000);
      }
    },
  };
}
