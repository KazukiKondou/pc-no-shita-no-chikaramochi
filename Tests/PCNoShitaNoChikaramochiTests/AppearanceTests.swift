import XCTest

@testable import PCNoShitaNoChikaramochi

final class AppearanceTests: XCTestCase {
    func testGenderCases() {
        XCTAssertEqual(Gender.allCases.count, 2)
        XCTAssertEqual(Gender.male.label, "男性")
        XCTAssertEqual(Gender.female.label, "女性")
        for g in Gender.allCases {
            XCTAssertEqual(g.id, g.rawValue)
        }
    }

    func testSkinToneCases() {
        XCTAssertEqual(SkinTone.allCases.count, 5)
        for tone in SkinTone.allCases {
            XCTAssertFalse(tone.label.isEmpty)
            XCTAssertEqual(tone.id, tone.rawValue)
        }
    }

    func testSkinToneColorsGenerate() {
        // primary / shade が全ケースで生成できること。
        XCTAssertEqual(SkinTone.allCases.map(\.primary).count, 5)
        XCTAssertEqual(SkinTone.allCases.map(\.shade).count, 5)
    }

    func testShirtColorCases() {
        XCTAssertEqual(ShirtColor.allCases.count, 8)
        for color in ShirtColor.allCases {
            XCTAssertFalse(color.label.isEmpty)
            XCTAssertEqual(color.id, color.rawValue)
        }
        XCTAssertEqual(Set(ShirtColor.allCases.map(\.label)).count, 8)
    }

    func testShirtColorsGenerate() {
        XCTAssertEqual(ShirtColor.allCases.map(\.primary).count, 8)
    }
}

@MainActor
final class AppearanceStoreTests: XCTestCase {
    private func makeEphemeralDefaults() -> UserDefaults {
        let suite = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    func testDefaults() {
        let store = AppearanceStore(defaults: makeEphemeralDefaults())
        XCTAssertEqual(store.gender, .male)
        XCTAssertEqual(store.skinTone, .light)
        XCTAssertEqual(store.shirtColor, .red)
    }

    func testSnapshotReflectsCurrentValues() {
        let store = AppearanceStore(defaults: makeEphemeralDefaults())
        store.gender = .female
        store.skinTone = .deep
        store.shirtColor = .pink
        XCTAssertEqual(
            store.snapshot,
            AppearanceSnapshot(gender: .female, skinTone: .deep, shirtColor: .pink)
        )
    }

    func testChangesPersistAcrossInstances() {
        let defaults = makeEphemeralDefaults()
        let store = AppearanceStore(defaults: defaults)
        store.gender = .female
        store.skinTone = .tan
        store.shirtColor = .green

        let reloaded = AppearanceStore(defaults: defaults)
        XCTAssertEqual(reloaded.gender, .female)
        XCTAssertEqual(reloaded.skinTone, .tan)
        XCTAssertEqual(reloaded.shirtColor, .green)
    }

    func testCorruptStoredValueFallsBackToDefault() {
        let defaults = makeEphemeralDefaults()
        defaults.set("not-a-real-color", forKey: AppearanceStore.keyShirt)
        let store = AppearanceStore(defaults: defaults)
        XCTAssertEqual(store.shirtColor, .red)
    }
}
