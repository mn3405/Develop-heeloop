import SwiftUI

struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var format: String = "%.0f"

    var body: some View {
        HStack {
            Text(title).font(.footnote).frame(width: 64, alignment: .leading)
            Slider(value: $value, in: range)
            Text(String(format: format, value))
                .font(.footnote.monospacedDigit())
                .frame(width: 44, alignment: .trailing)
        }
    }
}

/// 관절 선택 + 축별 회전 슬라이더
struct JointPanel: View {
    @ObservedObject var studio: DollStudio

    private func angle(_ axis: Int) -> Binding<Double> {
        Binding(
            get: { Double(studio.pose.angles[studio.selected]?[axis] ?? 0) },
            set: { newValue in
                var a = studio.pose.angles[studio.selected] ?? .zero
                a[axis] = Float(newValue)
                studio.pose.angles[studio.selected] = a
            })
    }

    var body: some View {
        let limits = studio.selected.limits
        let axes: [(String, Int, ClosedRange<Float>)] = [
            ("앞뒤", 0, limits.x), ("비틀기", 1, limits.y), ("좌우", 2, limits.z),
        ]
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Joint.allCases) { joint in
                        Button(joint.title) { studio.selected = joint }
                            .buttonStyle(.bordered)
                            .tint(joint == studio.selected ? .orange : .gray)
                    }
                }
                .padding(.horizontal)
            }
            VStack(spacing: 4) {
                ForEach(axes, id: \.1) { name, axis, range in
                    if range.lowerBound != range.upperBound {
                        LabeledSlider(title: name, value: angle(axis),
                                      range: Double(range.lowerBound)...Double(range.upperBound))
                    }
                }
            }
            .padding(.horizontal)
            Text("인형을 탭하면 관절이 선택돼요").font(.caption).foregroundStyle(.secondary)
        }
    }
}

/// 여성/남성/아이 + 키, 굵기, 비율
struct BodyPanel: View {
    @ObservedObject var studio: DollStudio

    private func bind(_ keyPath: WritableKeyPath<DollParameters, Float>) -> Binding<Double> {
        Binding(get: { Double(studio.params[keyPath: keyPath]) },
                set: { studio.params[keyPath: keyPath] = Float($0) })
    }

    var body: some View {
        let type = studio.params.bodyType
        ScrollView {
            VStack(spacing: 6) {
                Picker("모델", selection: Binding(get: { studio.params.bodyType },
                                                  set: { studio.setBodyType($0) })) {
                    ForEach(BodyType.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                LabeledSlider(title: "키(m)", value: bind(\.height),
                              range: Double(type.heightRange.lowerBound)...Double(type.heightRange.upperBound),
                              format: "%.2f")
                LabeledSlider(title: "굵기", value: bind(\.thickness), range: 0.6...1.6, format: "%.2f")
                LabeledSlider(title: "다리", value: bind(\.legScale), range: 0.7...1.3, format: "%.2f")
                LabeledSlider(title: "몸통", value: bind(\.torsoScale), range: 0.7...1.3, format: "%.2f")
                LabeledSlider(title: "팔", value: bind(\.armScale), range: 0.7...1.3, format: "%.2f")
                LabeledSlider(title: "머리", value: bind(\.headScale), range: 0.7...1.5, format: "%.2f")
                LabeledSlider(title: "어깨너비", value: bind(\.shoulderScale), range: 0.7...1.4, format: "%.2f")

                Button("비율 초기화") { studio.params = .defaults(for: type) }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
    }
}

/// 프리셋 포즈 + 골반 높이
struct PosePanel: View {
    @ObservedObject var studio: DollStudio

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(PosePreset.all) { preset in
                        Button(preset.name) { studio.pose = preset.pose }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)
            }
            LabeledSlider(
                title: "높이",
                value: Binding(get: { Double(studio.pose.rootY) },
                               set: { studio.pose.rootY = Float($0) }),
                range: -0.6...0.1, format: "%.2f")
                .padding(.horizontal)
            Button("포즈 초기화") { studio.resetPose() }
                .buttonStyle(.bordered)
        }
    }
}
