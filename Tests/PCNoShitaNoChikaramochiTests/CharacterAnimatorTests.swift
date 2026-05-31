import XCTest

@testable import PCNoShitaNoChikaramochi

@MainActor
final class CharacterAnimatorTests: XCTestCase {
    func testDefaultState() {
        let animator = CharacterAnimator()
        XCTAssertEqual(animator.state, .normal)
        XCTAssertEqual(animator.phase, 0.0)
    }

    func testUpdateChangesState() {
        let animator = CharacterAnimator()
        animator.update(usage: 95)
        XCTAssertEqual(animator.state, .crushed)
        animator.update(usage: 10)
        XCTAssertEqual(animator.state, .veryEasy)
    }

    func testStaticStateForcesPhaseToZero() {
        let animator = CharacterAnimator()
        animator.update(usage: 85)  // struggling: cycleDuration == nil
        animator.tick()
        XCTAssertEqual(animator.phase, 0.0)
    }

    func testAnimatedStatePhaseStaysInRange() {
        let animator = CharacterAnimator()
        animator.update(usage: 10)  // veryEasy
        for _ in 0..<50 {
            animator.tick()
            XCTAssertGreaterThanOrEqual(animator.phase, 0.0)
            XCTAssertLessThanOrEqual(animator.phase, 1.0)
        }
    }

    func testUpdateToSameStateIsIdempotent() {
        let animator = CharacterAnimator()
        animator.update(usage: 50)  // normal
        let first = animator.state
        animator.update(usage: 55)  // still normal
        XCTAssertEqual(animator.state, first)
    }
}
