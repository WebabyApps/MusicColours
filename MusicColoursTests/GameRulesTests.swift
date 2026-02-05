import XCTest
@testable import MusicColours_Watch_App

final class GameRulesTests: XCTestCase {
    func testDesiredColorCountCapsAtMax() {
        let result = GameRules.desiredColorCount(level: 10, baseCount: 4, availableCount: 20, maxCount: 8)
        XCTAssertEqual(result, 8)
    }

    func testDesiredColorCountUsesAvailableCount() {
        let result = GameRules.desiredColorCount(level: 10, baseCount: 4, availableCount: 6, maxCount: 8)
        XCTAssertEqual(result, 6)
    }

    func testShouldShuffleBonusEveryTwoChanges() {
        XCTAssertFalse(GameRules.shouldShuffleBonus(afterTargetChanges: 1))
        XCTAssertTrue(GameRules.shouldShuffleBonus(afterTargetChanges: 2))
        XCTAssertFalse(GameRules.shouldShuffleBonus(afterTargetChanges: 3))
        XCTAssertTrue(GameRules.shouldShuffleBonus(afterTargetChanges: 4))
    }
}
