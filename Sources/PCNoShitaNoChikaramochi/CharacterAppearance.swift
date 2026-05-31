import Foundation
import SwiftUI

enum Gender: String, CaseIterable, Identifiable {
    case male
    case female

    var id: String { rawValue }

    var label: String {
        switch self {
        case .male: return "男性"
        case .female: return "女性"
        }
    }
}

enum SkinTone: String, CaseIterable, Identifiable {
    case porcelain
    case light
    case medium
    case tan
    case deep

    var id: String { rawValue }

    var label: String {
        switch self {
        case .porcelain: return "とても明るい"
        case .light: return "明るい"
        case .medium: return "中間"
        case .tan: return "小麦"
        case .deep: return "濃い"
        }
    }

    var primary: Color {
        switch self {
        case .porcelain: return Color(red: 1.00, green: 0.92, blue: 0.84)
        case .light: return Color(red: 1.00, green: 0.84, blue: 0.66)
        case .medium: return Color(red: 0.86, green: 0.66, blue: 0.50)
        case .tan: return Color(red: 0.70, green: 0.50, blue: 0.35)
        case .deep: return Color(red: 0.42, green: 0.27, blue: 0.18)
        }
    }

    var shade: Color {
        switch self {
        case .porcelain: return Color(red: 0.88, green: 0.74, blue: 0.62)
        case .light: return Color(red: 0.78, green: 0.58, blue: 0.42)
        case .medium: return Color(red: 0.62, green: 0.42, blue: 0.28)
        case .tan: return Color(red: 0.48, green: 0.30, blue: 0.18)
        case .deep: return Color(red: 0.26, green: 0.15, blue: 0.08)
        }
    }
}

enum ShirtColor: String, CaseIterable, Identifiable {
    case red
    case blue
    case green
    case purple
    case orange
    case black
    case white
    case pink

    var id: String { rawValue }

    var label: String {
        switch self {
        case .red: return "赤"
        case .blue: return "青"
        case .green: return "緑"
        case .purple: return "紫"
        case .orange: return "橙"
        case .black: return "黒"
        case .white: return "白"
        case .pink: return "桃"
        }
    }

    var primary: Color {
        switch self {
        case .red: return Color(red: 0.84, green: 0.16, blue: 0.18)
        case .blue: return Color(red: 0.18, green: 0.45, blue: 0.85)
        case .green: return Color(red: 0.22, green: 0.60, blue: 0.35)
        case .purple: return Color(red: 0.50, green: 0.25, blue: 0.75)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.18)
        case .black: return Color(red: 0.15, green: 0.15, blue: 0.17)
        case .white: return Color(red: 0.95, green: 0.95, blue: 0.97)
        case .pink: return Color(red: 0.95, green: 0.55, blue: 0.70)
        }
    }
}

struct AppearanceSnapshot: Equatable {
    var gender: Gender
    var skinTone: SkinTone
    var shirtColor: ShirtColor
}

@MainActor
final class AppearanceStore: ObservableObject {
    @Published var gender: Gender {
        didSet { persist() }
    }
    @Published var skinTone: SkinTone {
        didSet { persist() }
    }
    @Published var shirtColor: ShirtColor {
        didSet { persist() }
    }

    static let keyGender = "appearance.gender"
    static let keySkin = "appearance.skin"
    static let keyShirt = "appearance.shirt"

    private let defaults: UserDefaults

    /// - Parameter defaults: 永続化先。テストでは独立した suite を渡せる。
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.gender = Gender(rawValue: defaults.string(forKey: Self.keyGender) ?? "") ?? .male
        self.skinTone = SkinTone(rawValue: defaults.string(forKey: Self.keySkin) ?? "") ?? .light
        self.shirtColor = ShirtColor(rawValue: defaults.string(forKey: Self.keyShirt) ?? "") ?? .red
    }

    var snapshot: AppearanceSnapshot {
        AppearanceSnapshot(gender: gender, skinTone: skinTone, shirtColor: shirtColor)
    }

    private func persist() {
        defaults.set(gender.rawValue, forKey: Self.keyGender)
        defaults.set(skinTone.rawValue, forKey: Self.keySkin)
        defaults.set(shirtColor.rawValue, forKey: Self.keyShirt)
    }
}
