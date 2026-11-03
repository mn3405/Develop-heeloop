import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { BODY_TYPES, defaultsFor } from './bodytype.js';
import { JOINTS, JOINT_INFO, PRESETS, CAMERA_PRESETS } from './pose.js';
import { buildRig } from './rig.js';

const state = {
  params: defaultsFor('male'),
  pose: { angles: {}, rootY: 0 },
  selected: 'shoulderL',
};

// ---------- Three.js 씬 ----------
const canvas = document.getElementById('canvas');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, preserveDrawingBuffer: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
const scene = new THREE.Scene();
scene.background = new THREE.Color(0xffffff);

const camera = new THREE.PerspectiveCamera(35, 1, 0.05, 50);
const controls = new OrbitControls(camera, canvas);
controls.enableDamping = true;

scene.add(new THREE.AmbientLight(0xffffff, 1.6));
const key = new THREE.DirectionalLight(0xffffff, 2.2);
key.position.set(2, 3, 2.5);
scene.add(key);
const fill = new THREE.DirectionalLight(0xffffff, 0.9);
fill.position.set(-2, 1, -2.5);
scene.add(fill);

const stage = new THREE.Mesh(
  new THREE.CylinderGeometry(0.6, 0.6, 0.004, 64),
  new THREE.MeshStandardMaterial({ color: 0xe6e6e6, roughness: 1 }),
);
stage.position.y = -0.002;
scene.add(stage);

let rig = null;
const target = () => new THREE.Vector3(0, state.params.height * 0.5, 0);

function rebuild() {
  if (rig) scene.remove(rig.root);
  rig = buildRig(state.params);
  scene.add(rig.root);
  rig.apply(state.pose);
  rig.highlight(state.selected);
  controls.target.copy(target());
}

let camAnim = null;
function moveCamera(preset, animated = true) {
  const t = target();
  const d = state.params.height * 2.3;
  const dir = new THREE.Vector3(...preset.dir).normalize();
  const to = t.clone().addScaledVector(dir, d);
  if (!animated) {
    camera.position.copy(to);
    controls.target.copy(t);
    camera.lookAt(t);
    return;
  }
  camAnim = { from: camera.position.clone(), to, fromT: controls.target.clone(), toT: t, start: performance.now() };
}

function tick(now) {
  if (camAnim) {
    const p = Math.min((now - camAnim.start) / 350, 1);
    const e = p * p * (3 - 2 * p);
    camera.position.lerpVectors(camAnim.from, camAnim.to, e);
    controls.target.lerpVectors(camAnim.fromT, camAnim.toT, e);
    if (p >= 1) camAnim = null;
  }
  controls.update();
  renderer.render(scene, camera);
  requestAnimationFrame(tick);
}

function resize() {
  const view = document.getElementById('view');
  const w = view.clientWidth, h = view.clientHeight;
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
}
window.addEventListener('resize', resize);

// ---------- 탭해서 관절 선택 ----------
const raycaster = new THREE.Raycaster();
let downAt = null;
canvas.addEventListener('pointerdown', (e) => { downAt = [e.clientX, e.clientY]; });
canvas.addEventListener('pointerup', (e) => {
  if (!downAt || Math.hypot(e.clientX - downAt[0], e.clientY - downAt[1]) > 5) return;
  const r = canvas.getBoundingClientRect();
  const ndc = new THREE.Vector2(((e.clientX - r.left) / r.width) * 2 - 1, -((e.clientY - r.top) / r.height) * 2 + 1);
  raycaster.setFromCamera(ndc, camera);
  const hit = raycaster.intersectObjects(rig.meshes, false)[0];
  if (hit) select(hit.object.userData.joint);
});

// ---------- 캡처 (PNG 다운로드) ----------
document.getElementById('capture').addEventListener('click', () => {
  rig.highlight(null);
  stage.visible = false;
  renderer.render(scene, camera);
  const url = canvas.toDataURL('image/png');
  stage.visible = true;
  rig.highlight(state.selected);
  const a = document.createElement('a');
  a.href = url;
  a.download = `heeloop-pose-${Date.now()}.png`;
  a.click();
  toast('PNG로 저장했어요 (다운로드 폴더)');
});

let toastTimer;
function toast(text) {
  const el = document.getElementById('toast');
  el.textContent = text;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2500);
}

// ---------- UI ----------
function slider(label, min, max, step, get, set, fmt) {
  const row = document.createElement('label');
  row.className = 'row';
  const name = document.createElement('span');
  name.textContent = label;
  const input = document.createElement('input');
  input.type = 'range';
  input.min = min; input.max = max; input.step = step;
  const val = document.createElement('output');
  const sync = () => { input.value = get(); val.textContent = fmt(get()); };
  input.addEventListener('input', () => { set(parseFloat(input.value)); val.textContent = fmt(parseFloat(input.value)); });
  row.append(name, input, val);
  sync();
  row.sync = sync;
  return row;
}

const f0 = (v) => v.toFixed(0);
const f2 = (v) => v.toFixed(2);

// 관절 탭
const jointChips = document.getElementById('joint-chips');
const jointSliders = document.getElementById('joint-sliders');

function renderJointPanel() {
  jointChips.innerHTML = '';
  for (const j of JOINTS) {
    const btn = document.createElement('button');
    btn.textContent = JOINT_INFO[j].title;
    if (j === state.selected) btn.classList.add('active');
    btn.onclick = () => select(j);
    jointChips.append(btn);
  }
  jointSliders.innerHTML = '';
  const limits = JOINT_INFO[state.selected].limits;
  ['앞뒤', '비틀기', '좌우'].forEach((label, axis) => {
    const [lo, hi] = limits[axis];
    if (lo === hi) return;
    jointSliders.append(slider(label, lo, hi, 1,
      () => (state.pose.angles[state.selected] || [0, 0, 0])[axis],
      (v) => {
        const a = (state.pose.angles[state.selected] ||= [0, 0, 0]);
        a[axis] = v;
        rig.apply(state.pose);
      }, f0));
  });
}

function select(j) {
  state.selected = j;
  rig.highlight(j);
  renderJointPanel();
  setTab('joint');
}

// 체형 탭
const bodyTypeBtns = document.getElementById('body-types');
const bodySliders = document.getElementById('body-sliders');
let bodyRows = [];

function renderBodyPanel() {
  bodyTypeBtns.innerHTML = '';
  for (const [id, info] of Object.entries(BODY_TYPES)) {
    const btn = document.createElement('button');
    btn.textContent = info.title;
    if (id === state.params.bodyType) btn.classList.add('active');
    btn.onclick = () => {
      state.params = defaultsFor(id);
      rebuild();
      moveCamera(CAMERA_PRESETS[0]);
      renderBodyPanel();
    };
    bodyTypeBtns.append(btn);
  }
  bodySliders.innerHTML = '';
  const [hMin, hMax] = BODY_TYPES[state.params.bodyType].heightRange;
  const defs = [
    ['키(m)', 'height', hMin, hMax, 0.01],
    ['굵기', 'thickness', 0.6, 1.6, 0.01],
    ['다리', 'legScale', 0.7, 1.3, 0.01],
    ['몸통', 'torsoScale', 0.7, 1.3, 0.01],
    ['팔', 'armScale', 0.7, 1.3, 0.01],
    ['머리', 'headScale', 0.7, 1.5, 0.01],
    ['어깨너비', 'shoulderScale', 0.7, 1.4, 0.01],
  ];
  bodyRows = defs.map(([label, key, min, max, step]) => {
    const row = slider(label, min, max, step, () => state.params[key], (v) => { state.params[key] = v; rebuild(); }, f2);
    bodySliders.append(row);
    return row;
  });
}
document.getElementById('reset-body').onclick = () => {
  state.params = defaultsFor(state.params.bodyType);
  rebuild();
  renderBodyPanel();
};

// 포즈 탭
const presetBox = document.getElementById('presets');
for (const p of PRESETS) {
  const btn = document.createElement('button');
  btn.textContent = p.name;
  btn.onclick = () => {
    state.pose = { angles: JSON.parse(JSON.stringify(p.angles)), rootY: p.rootY };
    rig.apply(state.pose);
    renderJointPanel();
    rootRow.sync();
  };
  presetBox.append(btn);
}
const rootRow = slider('높이', -0.6, 0.1, 0.01, () => state.pose.rootY, (v) => { state.pose.rootY = v; rig.apply(state.pose); }, f2);
document.getElementById('root-slider').append(rootRow);

// 카메라 버튼
const camBox = document.getElementById('cameras');
for (const p of CAMERA_PRESETS) {
  const btn = document.createElement('button');
  btn.textContent = p.name;
  btn.onclick = () => moveCamera(p);
  camBox.append(btn);
}

// 탭 전환
function setTab(name) {
  document.querySelectorAll('.tab').forEach((b) => b.classList.toggle('active', b.dataset.tab === name));
  document.querySelectorAll('.pane').forEach((p) => p.classList.toggle('hidden', p.id !== `pane-${name}`));
}
document.querySelectorAll('.tab').forEach((b) => { b.onclick = () => setTab(b.dataset.tab); });

// ---------- 시작 ----------
rebuild();
renderJointPanel();
renderBodyPanel();
resize();
moveCamera(CAMERA_PRESETS[0], false);
requestAnimationFrame(tick);

// 테스트/디버그용
window.__heeloop = { state, rebuild, moveCamera, select };
