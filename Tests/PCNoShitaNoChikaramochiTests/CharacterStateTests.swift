import XCTest

@testable import PCNoShitaNoChikaramochi

final class CharacterStateTests: XCTestCase {
    func testFromUsageBuckets() {
        XCTAssertEqual(CharacterState.from(usage: 0), .veryEasy)
        XCTAssertEqual(CharacterState.from(usage: 19.9), .veryEasy)
        XCTAssertEqual(CharacterState.from(usage: 20), .easy)
        XCTAssertEqual(CharacterState.from(usage: 39.9), .easy)
        XCTAssertEqual(CharacterState.from(usage: 40), .normal)
        XCTAssertEqual(CharacterState.from(usage: 59.9), .normal)
        XCTAssertEqual(CharacterState.from(usage: 60), .heavy)
        XCTAssertEqual(CharacterState.from(usage: 79.9), .heavy)
        XCTAssertEqual(CharacterState.from(usage: 80), .struggling)
        XCTAssertEqual(CharacterState.from(usage: 89.9), .struggling)
        XCTAssertEqual(CharacterState.from(usage: 90), .crushed)
        XCTAssertEqual(CharacterState.from(usage: 100), .crushed)
    }

    func testFromUsageHandlesOutOfRange() {
        XCTAssertEqual(CharacterState.from(usage: -10), .veryEasy)
        XCTAssertEqual(CharacterState.from(usage: 999), .crushed)
    }

    func testCycleDurationAnimatedStates() {
        XCTAssertEqual(CharacterState.veryEasy.cycleDuration, 0.4)
        XCTAssertEqual(CharacterState.easy.cycleDuration, 0.9)
        XCTAssertEqual(CharacterState.normal.cycleDuration, 1.6)
        XCTAssertEqual(CharacterState.heavy.cycleDuration, 3.2)
    }

    func testCycleDurationStaticStates() {
        XCTAssertNil(CharacterState.struggling.cycleDuration)
        XCTAssertNil(CharacterState.crushed.cycleDuration)
    }

    func testCycleDurationsAreMonotonicallyIncreasing() {
        let animated: [CharacterState] = [.veryEasy, .easy, .normal, .heavy]
        let durations = animated.compactMap(\.cycleDuration)
        XCTAssertEqual(durations, durations.sorted())
        XCTAssertEqual(durations.count, animated.count)
    }

    func testLiftKind() {
        XCTAssertEqual(CharacterState.veryEasy.liftKind, .dumbbell)
        XCTAssertEqual(CharacterState.easy.liftKind, .dumbbell)
        XCTAssertEqual(CharacterState.normal.liftKind, .dumbbell)
        XCTAssertEqual(CharacterState.heavy.liftKind, .barbell)
        XCTAssertEqual(CharacterState.struggling.liftKind, .barbell)
        XCTAssertEqual(CharacterState.crushed.liftKind, .barbell)
    }

    func testEveryCaseHasNonEmptyLabel() {
        for state in CharacterState.allCases {
            XCTAssertFalse(state.label.isEmpty, "\(state) のラベルが空")
        }
    }

    func testLabelsAreUnique() {
        let labels = CharacterState.allCases.map(\.label)
        XCTAssertEqual(Set(labels).count, labels.count)
    }

    func testEveryCaseProducesTint() {
        // Color は等価比較が不安定なので、全ケースで生成できること（クラッシュしないこと）を確認。
        XCTAssertEqual(CharacterState.allCases.map(\.tint).count, CharacterState.allCases.count)
    }
}
