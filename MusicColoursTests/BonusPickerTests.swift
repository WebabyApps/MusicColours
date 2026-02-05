import XCTest
@testable import MusicColours_Watch_App

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

final class BonusPickerTests: XCTestCase {
    func testPickBonusesReturnsEmptyForNoItems() {
        var rng = SeededGenerator(seed: 1)
        let result = BonusPicker.pickBonuses(from: [Int](), rng: &rng)
        XCTAssertTrue(result.isEmpty)
    }

    func testPickBonusesWithinExpectedRanges() {
        var rng = SeededGenerator(seed: 42)
        let items = Array(1...6)
        let result = BonusPicker.pickBonuses(from: items, rng: &rng)
        XCTAssertTrue((1...2).contains(result.count))
        for value in result.values {
            XCTAssertTrue((2...3).contains(value))
        }
    }
}
