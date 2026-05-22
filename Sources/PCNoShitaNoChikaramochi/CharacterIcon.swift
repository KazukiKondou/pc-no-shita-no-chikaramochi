import SwiftUI

/// メニューバーに表示する小さなキャラクターアイコン。
/// 100x100 の仮想座標で描いて、与えられたサイズにスケールする。
struct CharacterIcon: View {
    let state: CharacterState
    let phase: Double

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            paint(into: context, size: size)
        }
    }

    // MARK: - Colors

    private var shirtColor: Color { Color(red: 0.84, green: 0.16, blue: 0.18) }   // Japan red
    private var shirtShade: Color { Color(red: 0.62, green: 0.08, blue: 0.12) }
    private var skinColor: Color { Color(red: 1.0, green: 0.84, blue: 0.66) }
    private var skinShade: Color { Color(red: 0.78, green: 0.58, blue: 0.42) }
    private var hairColor: Color { Color(red: 0.18, green: 0.12, blue: 0.10) }
    private var shortsColor: Color { Color(red: 0.18, green: 0.18, blue: 0.22) }
    private var barColor: Color { Color(red: 0.78, green: 0.78, blue: 0.82) }
    private var plateColor: Color {
        switch state {
        case .veryEasy, .easy: return Color(red: 0.30, green: 0.65, blue: 0.95) // 軽い (青)
        case .normal:          return Color(red: 0.40, green: 0.75, blue: 0.40) // 中 (緑)
        case .heavy:           return Color(red: 0.95, green: 0.55, blue: 0.20) // 重い (橙)
        case .struggling:      return Color(red: 0.90, green: 0.25, blue: 0.25) // 超重 (赤)
        case .crushed:         return Color(red: 0.55, green: 0.10, blue: 0.10) // 致死量 (暗赤)
        }
    }

    // MARK: - Layout

    private func paint(into context: GraphicsContext, size: CGSize) {
        let s = min(size.width, size.height) / 100.0
        let cx = size.width / 2
        let cy = size.height / 2

        func P(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: cx + x * s, y: cy + y * s)
        }

        switch state {
        case .crushed:
            paintCrushed(context: context, scale: s, P: P)
        case .struggling:
            paintLifter(context: context, scale: s, P: P, armPhase: 0.45, leanY: 6, strain: true)
        case .heavy:
            paintLifter(context: context, scale: s, P: P, armPhase: phase * 0.9 + 0.05, leanY: 3, strain: true)
        default:
            paintLifter(context: context, scale: s, P: P, armPhase: phase, leanY: 0, strain: false)
        }
    }

    // MARK: - Standing lifter

    private func paintLifter(context: GraphicsContext,
                             scale s: CGFloat,
                             P: (Double, Double) -> CGPoint,
                             armPhase t: Double,
                             leanY: Double,
                             strain: Bool) {
        var ctx = context

        // ---- 脚 ----
        let legW = 8.0
        let legTop = 18.0 + leanY
        let legBot = 42.0 + leanY
        let legL = Path { p in
            p.addRoundedRect(in: rect(P, x: -8, y: legTop, w: legW, h: legBot - legTop), cornerSize: CGSize(width: 3 * s, height: 3 * s))
        }
        let legR = Path { p in
            p.addRoundedRect(in: rect(P, x: 8 - legW, y: legTop, w: legW, h: legBot - legTop), cornerSize: CGSize(width: 3 * s, height: 3 * s))
        }
        ctx.fill(legL, with: .color(shortsColor))
        ctx.fill(legR, with: .color(shortsColor))

        // ---- 胴体 (赤シャツ) ----
        let torsoTop = -8.0 + leanY
        let torsoBot = 20.0 + leanY
        let torso = Path { p in
            p.addRoundedRect(in: rect(P, x: -14, y: torsoTop, w: 28, h: torsoBot - torsoTop), cornerSize: CGSize(width: 4 * s, height: 4 * s))
        }
        ctx.fill(torso, with: .color(shirtColor))

        // 胸の白丸 (日の丸イメージ)
        let dot = Path(ellipseIn: rect(P, x: -3, y: torsoTop + 7, w: 6, h: 6))
        ctx.fill(dot, with: .color(.white.opacity(0.92)))

        // ---- 首 ----
        let neck = Path { p in
            p.addRect(rect(P, x: -3, y: -12 + leanY, w: 6, h: 5))
        }
        ctx.fill(neck, with: .color(skinShade))

        // ---- 頭 ----
        let headCY = -22.0 + leanY
        let head = Path(ellipseIn: rect(P, x: -10, y: headCY - 10, w: 20, h: 20))
        ctx.fill(head, with: .color(skinColor))

        // 髪
        let hair = Path { p in
            p.move(to: P(-10, headCY - 5))
            p.addQuadCurve(to: P(10, headCY - 5), control: P(0, headCY - 13))
            p.addLine(to: P(8, headCY - 2))
            p.addQuadCurve(to: P(-8, headCY - 2), control: P(0, headCY - 6))
            p.closeSubpath()
        }
        ctx.fill(hair, with: .color(hairColor))

        // ---- 顔 ----
        drawFace(context: &ctx, P: P, scale: s, headCY: headCY, strain: strain)

        // ---- 腕 + ウェイト ----
        let liftKind = state.liftKind

        // 肩位置
        let leftShoulder = P(-12, -6 + leanY)
        let rightShoulder = P(12, -6 + leanY)

        // 手位置: tに応じて下→上に動く
        let handDownY = 14.0 + leanY
        let handUpY = headCY - 22.0   // 頭の上
        let handY = handDownY + (handUpY - handDownY) * t

        let handXSpread = 16.0 + (1.0 - t) * 6.0
        let leftHand = P(-handXSpread, handY)
        let rightHand = P(handXSpread, handY)

        // 腕 (肩→手)
        let armWidth = 5.5 * s
        var leftArm = Path()
        leftArm.move(to: leftShoulder)
        leftArm.addLine(to: leftHand)
        ctx.stroke(leftArm, with: .color(skinColor), style: StrokeStyle(lineWidth: armWidth, lineCap: .round))

        var rightArm = Path()
        rightArm.move(to: rightShoulder)
        rightArm.addLine(to: rightHand)
        ctx.stroke(rightArm, with: .color(skinColor), style: StrokeStyle(lineWidth: armWidth, lineCap: .round))

        // ---- ウェイト描画 ----
        switch liftKind {
        case .dumbbell:
            drawDumbbell(context: &ctx, P: P, at: leftHand, scale: s)
            drawDumbbell(context: &ctx, P: P, at: rightHand, scale: s)
        case .barbell:
            drawBarbell(context: &ctx, leftHand: leftHand, rightHand: rightHand, scale: s, strain: strain)
        }

        // 「上がらない」状態は震えや汗を表現
        if state == .struggling {
            drawSweat(context: &ctx, P: P, scale: s, headCY: headCY)
        }
    }

    // MARK: - Crushed (倒れて踏み潰されてる)

    private func paintCrushed(context: GraphicsContext,
                              scale s: CGFloat,
                              P: (Double, Double) -> CGPoint) {
        var ctx = context

        // 地面ライン (床)
        var ground = Path()
        ground.move(to: P(-45, 38))
        ground.addLine(to: P(45, 38))
        ctx.stroke(ground, with: .color(.gray.opacity(0.4)), style: StrokeStyle(lineWidth: 1.5 * s))

        // 横たわった身体 (右向き)
        // 脚
        let legs = Path { p in
            p.addRoundedRect(in: rect(P, x: -22, y: 28, w: 30, h: 8), cornerSize: CGSize(width: 4 * s, height: 4 * s))
        }
        ctx.fill(legs, with: .color(shortsColor))

        // 胴体 (赤シャツ、横倒し)
        let torso = Path { p in
            p.addRoundedRect(in: rect(P, x: -6, y: 16, w: 28, h: 12), cornerSize: CGSize(width: 4 * s, height: 4 * s))
        }
        ctx.fill(torso, with: .color(shirtColor))

        // 頭 (右側)
        let head = Path(ellipseIn: rect(P, x: 17, y: 13, w: 18, h: 18))
        ctx.fill(head, with: .color(skinColor))

        // 髪 (頭頂、右向きなので右側)
        let hair = Path { p in
            p.move(to: P(30, 14))
            p.addQuadCurve(to: P(34, 23), control: P(38, 17))
            p.addLine(to: P(30, 22))
            p.closeSubpath()
        }
        ctx.fill(hair, with: .color(hairColor))

        // X目
        let eyeSize = 2.4
        for (ex, ey) in [(25.0, 19.0), (29.0, 21.0)] {
            var x1 = Path()
            x1.move(to: P(ex - eyeSize, ey - eyeSize))
            x1.addLine(to: P(ex + eyeSize, ey + eyeSize))
            var x2 = Path()
            x2.move(to: P(ex + eyeSize, ey - eyeSize))
            x2.addLine(to: P(ex - eyeSize, ey + eyeSize))
            ctx.stroke(x1, with: .color(.black), style: StrokeStyle(lineWidth: 1.4 * s, lineCap: .round))
            ctx.stroke(x2, with: .color(.black), style: StrokeStyle(lineWidth: 1.4 * s, lineCap: .round))
        }

        // 舌出し
        let tongue = Path { p in
            p.addRoundedRect(in: rect(P, x: 23, y: 25, w: 4, h: 3), cornerSize: CGSize(width: 1.5 * s, height: 1.5 * s))
        }
        ctx.fill(tongue, with: .color(Color(red: 0.95, green: 0.45, blue: 0.55)))

        // ---- バーベル (胴体の上に乗っかってる) ----
        let barY = 8.0
        let barLeft = P(-45, barY)
        let barRight = P(45, barY)
        var bar = Path()
        bar.move(to: barLeft)
        bar.addLine(to: barRight)
        ctx.stroke(bar, with: .color(barColor), style: StrokeStyle(lineWidth: 4.5 * s, lineCap: .round))

        // 大きなプレート
        drawPlate(context: &ctx, P: P, x: -42, y: barY, w: 12, h: 32)
        drawPlate(context: &ctx, P: P, x: 30, y: barY, w: 12, h: 32)
        drawPlate(context: &ctx, P: P, x: -28, y: barY, w: 6, h: 22)
        drawPlate(context: &ctx, P: P, x: 22, y: barY, w: 6, h: 22)

        // 衝撃線
        for (dx, dy) in [(-30.0, -5.0), (32.0, -8.0), (0.0, -14.0)] {
            var line = Path()
            line.move(to: P(dx - 3, dy - 3))
            line.addLine(to: P(dx + 3, dy + 3))
            var line2 = Path()
            line2.move(to: P(dx + 3, dy - 3))
            line2.addLine(to: P(dx - 3, dy + 3))
            ctx.stroke(line, with: .color(.yellow.opacity(0.9)), style: StrokeStyle(lineWidth: 1.5 * s))
            ctx.stroke(line2, with: .color(.yellow.opacity(0.9)), style: StrokeStyle(lineWidth: 1.5 * s))
        }
    }

    // MARK: - Sub helpers

    private func drawFace(context: inout GraphicsContext,
                          P: (Double, Double) -> CGPoint,
                          scale s: CGFloat,
                          headCY: Double,
                          strain: Bool) {
        // 目
        let eyeY = headCY - 1.0
        let eyeOffsetX = 3.5
        let eyeR = 1.6

        if state == .veryEasy {
            // にっこり閉じ目 ^_^
            for sign in [-1.0, 1.0] {
                var eye = Path()
                eye.move(to: P(sign * eyeOffsetX - 2, eyeY + 1))
                eye.addQuadCurve(to: P(sign * eyeOffsetX + 2, eyeY + 1), control: P(sign * eyeOffsetX, eyeY - 2))
                context.stroke(eye, with: .color(.black), style: StrokeStyle(lineWidth: 1.3 * s, lineCap: .round))
            }
        } else if strain {
            // しかめ目 >_<
            for sign in [-1.0, 1.0] {
                var eye = Path()
                eye.move(to: P(sign * eyeOffsetX - 2, eyeY - 1))
                eye.addQuadCurve(to: P(sign * eyeOffsetX + 2, eyeY - 1), control: P(sign * eyeOffsetX, eyeY + 2))
                context.stroke(eye, with: .color(.black), style: StrokeStyle(lineWidth: 1.4 * s, lineCap: .round))
            }
        } else {
            // 普通の点目
            for sign in [-1.0, 1.0] {
                let eye = Path(ellipseIn: rect(P, x: sign * eyeOffsetX - eyeR, y: eyeY - eyeR, w: eyeR * 2, h: eyeR * 2))
                context.fill(eye, with: .color(.black))
            }
        }

        // 口
        let mouthY = headCY + 4.0
        switch state {
        case .veryEasy, .easy:
            // にっこり
            var mouth = Path()
            mouth.move(to: P(-3, mouthY))
            mouth.addQuadCurve(to: P(3, mouthY), control: P(0, mouthY + 2.5))
            context.stroke(mouth, with: .color(.black), style: StrokeStyle(lineWidth: 1.2 * s, lineCap: .round))
        case .normal:
            // 普通の一文字
            var mouth = Path()
            mouth.move(to: P(-2, mouthY))
            mouth.addLine(to: P(2, mouthY))
            context.stroke(mouth, with: .color(.black), style: StrokeStyle(lineWidth: 1.2 * s, lineCap: .round))
        case .heavy:
            // 食いしばり (歯)
            let m = rect(P, x: -3, y: mouthY - 1, w: 6, h: 2.5)
            context.fill(Path(roundedRect: m, cornerSize: CGSize(width: 0.5 * s, height: 0.5 * s)), with: .color(.white))
            context.stroke(Path(roundedRect: m, cornerSize: CGSize(width: 0.5 * s, height: 0.5 * s)),
                           with: .color(.black), style: StrokeStyle(lineWidth: 0.8 * s))
            var mid = Path()
            mid.move(to: P(0, mouthY - 1))
            mid.addLine(to: P(0, mouthY + 1.5))
            context.stroke(mid, with: .color(.black), style: StrokeStyle(lineWidth: 0.6 * s))
        case .struggling:
            // 大きく開いた口 (うわー)
            let m = rect(P, x: -3, y: mouthY - 1, w: 6, h: 4)
            context.fill(Path(roundedRect: m, cornerSize: CGSize(width: 1.5 * s, height: 1.5 * s)),
                         with: .color(Color(red: 0.45, green: 0.10, blue: 0.10)))
        case .crushed:
            break
        }

        // veryEasy なら頬にキラキラ
        if state == .veryEasy {
            for sign in [-1.0, 1.0] {
                let star = Path { p in
                    let cx = sign * 7.5
                    let cy = headCY + 3.0
                    p.move(to: P(cx, cy - 1.5))
                    p.addLine(to: P(cx + 0.6, cy - 0.4))
                    p.addLine(to: P(cx + 1.5, cy))
                    p.addLine(to: P(cx + 0.6, cy + 0.4))
                    p.addLine(to: P(cx, cy + 1.5))
                    p.addLine(to: P(cx - 0.6, cy + 0.4))
                    p.addLine(to: P(cx - 1.5, cy))
                    p.addLine(to: P(cx - 0.6, cy - 0.4))
                    p.closeSubpath()
                }
                context.fill(star, with: .color(.yellow))
            }
        }
    }

    private func drawDumbbell(context: inout GraphicsContext,
                              P: (Double, Double) -> CGPoint,
                              at hand: CGPoint,
                              scale s: CGFloat) {
        // ハンドル
        let handleW = 12.0 * s
        let handleH = 2.5 * s
        let handle = CGRect(x: hand.x - handleW / 2, y: hand.y - handleH / 2, width: handleW, height: handleH)
        context.fill(Path(roundedRect: handle, cornerSize: CGSize(width: 1 * s, height: 1 * s)), with: .color(barColor))

        // 両端の重り
        for offset in [-7.0 * s, 7.0 * s] {
            let wW = 4.0 * s
            let wH = 8.0 * s
            let weight = CGRect(x: hand.x + offset - wW / 2, y: hand.y - wH / 2, width: wW, height: wH)
            context.fill(Path(roundedRect: weight, cornerSize: CGSize(width: 1.2 * s, height: 1.2 * s)),
                         with: .color(plateColor))
        }
    }

    private func drawBarbell(context: inout GraphicsContext,
                             leftHand: CGPoint,
                             rightHand: CGPoint,
                             scale s: CGFloat,
                             strain: Bool) {
        // バー (両手を結ぶ + 外側に伸びる)
        let extend = 12.0 * s
        let dx = rightHand.x - leftHand.x
        let dy = rightHand.y - leftHand.y
        let len = max(0.001, sqrt(dx * dx + dy * dy))
        let ux = dx / len
        let uy = dy / len
        let barLeft = CGPoint(x: leftHand.x - ux * extend, y: leftHand.y - uy * extend)
        let barRight = CGPoint(x: rightHand.x + ux * extend, y: rightHand.y + uy * extend)

        var bar = Path()
        bar.move(to: barLeft)
        bar.addLine(to: barRight)
        context.stroke(bar, with: .color(barColor), style: StrokeStyle(lineWidth: 3.5 * s, lineCap: .round))

        // 両端のプレート (重い色)
        let plateW: Double = 5.5
        let plateH: Double = strain ? 22.0 : 18.0

        drawPlateRotated(context: &context, center: barLeft, perpUx: -uy, perpUy: ux, w: plateW, h: plateH, scale: s)
        drawPlateRotated(context: &context, center: barRight, perpUx: -uy, perpUy: ux, w: plateW, h: plateH, scale: s)

        // 内側に小プレート (1枚追加)
        let innerL = CGPoint(x: barLeft.x + ux * 4 * s, y: barLeft.y + uy * 4 * s)
        let innerR = CGPoint(x: barRight.x - ux * 4 * s, y: barRight.y - uy * 4 * s)
        drawPlateRotated(context: &context, center: innerL, perpUx: -uy, perpUy: ux, w: 3.0, h: plateH * 0.6, scale: s)
        drawPlateRotated(context: &context, center: innerR, perpUx: -uy, perpUy: ux, w: 3.0, h: plateH * 0.6, scale: s)
    }

    private func drawPlateRotated(context: inout GraphicsContext,
                                  center: CGPoint,
                                  perpUx: CGFloat, perpUy: CGFloat,
                                  w: Double, h: Double,
                                  scale s: CGFloat) {
        // バーに垂直な向きの楕円を描く
        let plateW = w * s
        let plateH = h * s
        // 中心を center、長軸を (perpUx, perpUy) 方向にした楕円
        // 簡略化のため、垂直方向に近い場合は普通の楕円で描く
        let rect = CGRect(x: center.x - plateW / 2, y: center.y - plateH / 2, width: plateW, height: plateH)
        context.fill(Path(ellipseIn: rect), with: .color(plateColor))
        context.stroke(Path(ellipseIn: rect), with: .color(.black.opacity(0.4)), style: StrokeStyle(lineWidth: 0.6 * s))
    }

    private func drawPlate(context: inout GraphicsContext,
                           P: (Double, Double) -> CGPoint,
                           x: Double, y: Double, w: Double, h: Double) {
        let r = rect(P, x: x - w / 2, y: y - h / 2, w: w, h: h)
        context.fill(Path(ellipseIn: r), with: .color(plateColor))
        context.stroke(Path(ellipseIn: r), with: .color(.black.opacity(0.4)), style: StrokeStyle(lineWidth: 0.6))
    }

    private func drawSweat(context: inout GraphicsContext,
                           P: (Double, Double) -> CGPoint,
                           scale s: CGFloat,
                           headCY: Double) {
        // 右こめかみの汗
        var sweat = Path()
        let sx = 10.5
        let sy = headCY + 0.0
        sweat.move(to: P(sx, sy - 2))
        sweat.addQuadCurve(to: P(sx + 2, sy + 2), control: P(sx + 2.5, sy))
        sweat.addQuadCurve(to: P(sx, sy - 2), control: P(sx - 2.5, sy))
        sweat.closeSubpath()
        context.fill(sweat, with: .color(Color(red: 0.40, green: 0.75, blue: 0.95)))
    }

    private func rect(_ P: (Double, Double) -> CGPoint, x: Double, y: Double, w: Double, h: Double) -> CGRect {
        let topLeft = P(x, y)
        let bottomRight = P(x + w, y + h)
        return CGRect(x: topLeft.x, y: topLeft.y,
                      width: bottomRight.x - topLeft.x,
                      height: bottomRight.y - topLeft.y)
    }
}
