import XCTest
@testable import MusicColours_Watch_App

final class BestScoresStoreTests: XCTestCase {
    func testRecordAndReset() {
        let defaults = UserDefaults(suiteName: "BestScoresStoreTests")!
        defaults.removePersistentDomain(forName: "BestScoresStoreTests")
        let store = BestScoresStore(key: "scores", defaults: defaults, limit: 5)

        XCTAssertEqual(store.load(), [])

        var updated = store.record(score: 3, avatarId: "avatar_cat")
        XCTAssertEqual(updated.count, 1)
        XCTAssertEqual(updated.first?.score, 3)

        updated = store.record(score: 10, avatarId: "avatar_dog")
        XCTAssertEqual(updated.count, 2)
        XCTAssertEqual(updated.last?.score, 10)

        _ = store.record(score: 5, avatarId: "avatar_cat")
        _ = store.record(score: 8, avatarId: "avatar_cat")
        _ = store.record(score: 1, avatarId: "avatar_cat")
        _ = store.record(score: 12, avatarId: "avatar_cat")

        let loaded = store.load()
        XCTAssertEqual(loaded.map { $0.score }, [10, 5, 8, 1, 12])

        store.reset()
        XCTAssertEqual(store.load(), [])
    }
}
