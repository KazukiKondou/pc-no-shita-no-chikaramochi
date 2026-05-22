import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: AppearanceStore
    @ObservedObject var animator: CharacterAnimator
    @ObservedObject var monitor: MemoryMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                // プレビュー
                VStack(spacing: 6) {
                    CharacterIcon(
                        state: animator.state,
                        phase: animator.phase,
                        appearance: store.snapshot
                    )
                    .frame(width: 140, height: 140)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                    Text(animator.state.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "メモリ %.1f%%", monitor.usage))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 160)

                Divider()

                VStack(alignment: .leading, spacing: 18) {
                    // 性別
                    VStack(alignment: .leading, spacing: 6) {
                        Text("性別").font(.headline)
                        Picker("性別", selection: $store.gender) {
                            ForEach(Gender.allCases) { g in
                                Text(g.label).tag(g)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    // 肌色
                    VStack(alignment: .leading, spacing: 6) {
                        Text("肌の色").font(.headline)
                        HStack(spacing: 10) {
                            ForEach(SkinTone.allCases) { tone in
                                SwatchButton(
                                    color: tone.primary,
                                    selected: store.skinTone == tone,
                                    label: tone.label
                                ) {
                                    store.skinTone = tone
                                }
                            }
                        }
                    }

                    // シャツの色
                    VStack(alignment: .leading, spacing: 6) {
                        Text("シャツの色").font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 8), count: 8), alignment: .leading, spacing: 8) {
                            ForEach(ShirtColor.allCases) { color in
                                SwatchButton(
                                    color: color.primary,
                                    selected: store.shirtColor == color,
                                    label: color.label
                                ) {
                                    store.shirtColor = color
                                }
                            }
                        }
                    }
                }
            }

            Divider()

            Text("変更は即座にメニューバーへ反映されます。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 580, height: 340)
    }
}

private struct SwatchButton: View {
    let color: Color
    let selected: Bool
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(selected ? Color.accentColor : Color.gray.opacity(0.35),
                                lineWidth: selected ? 3 : 1)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 1)
                        .opacity(selected ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
        .help(label)
    }
}
