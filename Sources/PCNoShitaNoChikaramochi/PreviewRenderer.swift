import AppKit
import SwiftUI

/// 開発用: 各状態のキャラクターを PNG に書き出すオフスクリーンレンダラ。
///
/// `PCNoShitaNoChikaramochi --render-previews <出力ディレクトリ>` で起動すると、
/// 全状態 × 代表的な見た目を PNG 化して終了する。デザイン確認・回帰確認に使う。
@MainActor
enum PreviewRenderer {
    /// 指定ディレクトリへ全状態の PNG を書き出す。書き出した枚数を返す。
    @discardableResult
    static func renderAll(to directory: URL, pixelSize: CGFloat = 240) -> Int {
        let fm = FileManager.default
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)

        let appearance = AppearanceSnapshot(gender: .male, skinTone: .light, shirtColor: .red)
        var count = 0

        for state in CharacterState.allCases {
            // 上げきった姿勢 (phase = 1) を代表として描く
            if writePNG(
                state: state,
                phase: 1.0,
                appearance: appearance,
                pixelSize: pixelSize,
                to: directory.appendingPathComponent("state-\(state).png")
            ) {
                count += 1
            }
        }

        // 女性 + 別の肌色 / シャツ色のバリエーションも 1 枚
        let variant = AppearanceSnapshot(gender: .female, skinTone: .tan, shirtColor: .purple)
        if writePNG(
            state: .normal,
            phase: 1.0,
            appearance: variant,
            pixelSize: pixelSize,
            to: directory.appendingPathComponent("variant-female.png")
        ) {
            count += 1
        }

        return count
    }

    private static func writePNG(
        state: CharacterState,
        phase: Double,
        appearance: AppearanceSnapshot,
        pixelSize: CGFloat,
        to url: URL
    ) -> Bool {
        let view = CharacterIcon(state: state, phase: phase, appearance: appearance)
            .frame(width: pixelSize, height: pixelSize)
            .background(Color(white: 0.96))

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        guard
            let cgImage = renderer.cgImage,
            let pngData = NSBitmapImageRep(cgImage: cgImage)
                .representation(using: .png, properties: [:])
        else {
            return false
        }
        do {
            try pngData.write(to: url)
            return true
        } catch {
            return false
        }
    }
}
