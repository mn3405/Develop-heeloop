# Heeloop Pose

3D 관절 인형으로 포즈를 만들고, 원하는 각도에서 캡처해 전용 사진 앨범(`Heeloop Pose`)에 모으는 iOS 앱.
크로키어리의 "앨범 불러오기"로 바로 가져다 쓸 수 있다.

## 실행 방법 (Mac + Xcode 15 이상 필요)

```bash
brew install xcodegen
xcodegen generate        # project.yml -> HeeloopPose.xcodeproj
open HeeloopPose.xcodeproj
```

Signing에서 본인 Team을 선택하고 iPhone(iOS 17+)에서 실행한다. 사진 권한 팝업은 허용해야 저장된다.
(`.xcodeproj`와 `Info.plist`는 생성물이라 git에 올리지 않는다.)

## 웹 미리보기 (Windows/Mac 어디서나)

Xcode 없이 브라우저로 마네킹 모양과 관절 움직임을 확인할 수 있다.

- `web/index.html`을 더블클릭해서 Chrome/Edge로 열면 된다 (설치·서버 불필요).
- 아이폰 앱과 같은 체형 비율, 관절 한계각, 프리셋을 쓴다. 📷 버튼은 PNG 다운로드.
- 소스는 `web/src/`, 번들(`web/app.js`)을 다시 만들려면 `cd web && npm install && npm run build`.
- 비율 숫자는 `web/src/bodytype.js`와 `HeeloopPose/Model/BodyType.swift`가 같은 값이다. 한쪽을 고치면 다른 쪽도 맞춰 준다.

## 현재 기능 (1~2단계)

- 코드로 만든 마네킹 3종: 여성 / 남성 / 아이
- 슬라이더: 키, 굵기, 다리·몸통·팔 길이, 머리 크기, 어깨너비
- 관절 17개를 슬라이더로 회전 (인형을 탭해 관절 선택), 프리셋 포즈, 골반 높이
- 한 손가락 드래그로 회전, 두 손가락으로 확대, 정면/3/4/좌/우/뒷면 버튼
- 카메라 버튼: 고해상도 PNG 캡처 -> `Heeloop Pose` 앨범에 자동 저장 (앨범 이름은 `PhotoAlbumSaver.albumTitle`)

## 구조

```
HeeloopPose/
  Model/    Pose(관절·포즈), BodyType(체형 비율), DollRig(마네킹 생성), DollStudio(씬·카메라·캡처)
  Services/ PhotoAlbumSaver (전용 앨범 저장)
  Views/    ContentView, DollSceneView, ControlPanels
```

## 모델 교체 / 수정

- 체형 비율: `BodyType.swift`의 숫자(키 대비 비율)만 바꾸면 된다.
- 외형: `DollRig.swift`의 `build()`에서 도형을 바꾸거나, 같은 인터페이스(`root`, `apply`, `highlight`)로
  USDZ 모델을 불러오는 리그를 만들어 `DollStudio.rebuild()`에서 교체하면 된다.

## 다음 단계 (3단계)

사진에서 포즈 추출: Vision `VNDetectHumanBodyPose3DRequest`(iOS 17+)로 3D 관절 위치를 얻어
각 뼈의 방향을 `Pose.angles`로 변환한다.
