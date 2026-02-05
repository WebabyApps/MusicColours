import XCTest
@testable import MusicColours_Watch_App

final class BestScoresStoreTests: XCTestCase {
    func testRecordAndReset() {
        let defaults = UserDefaults(suiteName: "BestScoresStoreTests")!
        defaults.removePersistentDomain(forName: "BestScoresStoreTests")
        let store = BestScoresStore(key: "scores", defaults: defaults, limit: 5)

        XCTAssertEqual(store.load(), [])

        var updated = store.record(3)
        XCTAssertEqual(updated, [3])

        updated = store.record(10)
        XCTAssertEqual(updated, [3, 10])

        _ = store.record(5)
        _ = store.record(8)
        _ = store.record(1)
        _ = store.record(12)

        XCTAssertEqual(store.load(), [10, 5, 8, 1, 12])

        store.reset()
        XCTAssertEqual(store.load(), [])
    }
}
