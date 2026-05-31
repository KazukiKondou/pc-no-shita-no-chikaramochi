import Foundation
import SwiftUI

enum CharacterState: Int, CaseIterable {
    case veryEasy  // <20%   ダンベル超速
    case easy  // 20-40% ダンベル少し遅く
    case normal  // 40-60% ダンベルゆっくり
    case heavy  // 60-80% 重量挙げ (ゆっくり頑張る)
    case struggling  // 80-90% 上がらない
    case crushed  // 90%+   踏み潰される

    static func from(usage: Double) -> CharacterState {
        switch usage {
        case ..<20: return .veryEasy
        case ..<40: return .easy
        case ..<60: return .normal
        case ..<80: return .heavy
        case ..<90: return .struggling
        default: return .crushed
        }
    }

    /// 1サイクル (上げて下ろす) にかける秒数。nil なら静止。
    var cycleDuration: TimeInterval? {
        switch self {
        case .veryEasy: return 0.4
        case .easy: return 0.9
        case .normal: return 1.6
        case .heavy: return 3.2
        case .struggling: return nil
        case .crushed: return nil
        }
    }

    /// ダンベルかバーベルか
    var liftKind: LiftKind {
        switch self {
        case .veryEasy, .easy, .normal: return .dumbbell
        case .heavy, .struggling, .crushed: return .barbell
        }
    }

    var label: String {
        switch self {
        case .veryEasy: return "余裕！"
        case .easy: return "軽い軽い"
        case .normal: return "ふつう"
        case .heavy: return "ぐぬぬ…"
        case .struggling: return "上がらん！！"
        case .crushed: return "ぺしゃんこ…"
        }
    }

    var tint: Color {
        switch self {
        case .veryEasy: return Color(red: 0.95, green: 0.78, blue: 0.30)
        case .easy: return Color(red: 0.95, green: 0.78, blue: 0.30)
        case .normal: return Color(red: 0.85, green: 0.70, blue: 0.30)
        case .heavy: return Color(red: 0.95, green: 0.55, blue: 0.25)
        case .struggling: return Color(red: 0.90, green: 0.35, blue: 0.25)
        case .crushed: return Color(red: 0.55, green: 0.22, blue: 0.22)
        }
    }
}

enum LiftKind {
    case dumbbell
    case barbell
}

@MainActor
final class CharacterAnimator: ObservableObject {
    @Published var state: CharacterState = .normal
    /// 0.0 = 下げきった姿勢, 1.0 = 上げきった姿勢
    @Published var phase: Double = 0.0

    private var timer: Timer?
    private var startTime: Date = Date()

    func start() {
        startTime = Date()
        // .common モードで登録することで、メニュー開いてる間もアニメーションが動く
        let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func update(usage: Double) {
        let newState = CharacterState.from(usage: usage)
        if newState != state {
            state = newState
            startTime = Date()
        }
    }

    /// アニメーションの 1 フレームを進める。テストから直接呼べるよう internal。
    func tick() {
        guard let duration = state.cycleDuration else {
            phase = 0
            return
        }
        let elapsed = Date().timeIntervalSince(startTime)
        let t = (elapsed.truncatingRemainder(dividingBy: duration)) / duration
        // 0..1..0 の三角波で上下動を表現
        phase = t < 0.5 ? t * 2 : 2 - t * 2
    }
}
