import Foundation

struct GameRules {
    static func desiredColorCount(level: Int, baseCount: Int, availableCount: Int, maxCount: Int = 8) -> Int {
        let extra = max(0, level - 1)
        let desired = baseCount + extra
        return min(maxCount, availableCount, desired)
    }

    static func shouldShuffleBonus(afterTargetChanges count: Int) -> Bool {
        count % 2 == 0
    }
}

struct BonusPicker {
    static func pickBonuses<T: Hashable>(
        from items: [T],
        bonusCountRange: ClosedRange<Int> = 1...2,
        bonusValueRange: ClosedRange<Int> = 2...3,
        rng: inout RandomNumberGenerator
    ) -> [T: Int] {
        guard !items.isEmpty else { return [:] }
        let maxCount = min(bonusCountRange.upperBound, items.count)
        let minCount = min(bonusCountRange.lowerBound, maxCount)
        let count = Int.random(in: minCount...maxCount, using: &rng)
        let selected = items.shuffled(using: &rng).prefix(count)
        var map: [T: Int] = [:]
        for item in selected {
            map[item] = Int.random(in: bonusValueRange, using: &rng)
        }
        return map
    }
}

struct BestScoresStore {
    let key: String
    let defaults: UserDefaults
    let limit: Int

    init(key: String, defaults: UserDefaults = .standard, limit: Int = 5) {
        self.key = key
        self.defaults = defaults
        self.limit = limit
    }

    func load() -> [RecordEntry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([RecordEntry].self, from: data)) ?? []
    }

    @discardableResult
    func record(score: Int, avatarId: String) -> [RecordEntry] {
        var updated = load()
        updated.append(RecordEntry(score: score, avatarId: avatarId, createdAt: Date()))
        if updated.count > limit { updated = Array(updated.suffix(limit)) }
        if let data = try? JSONEncoder().encode(updated) {
            defaults.set(data, forKey: key)
        }
        return updated
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}

struct RecordEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let score: Int
    let avatarId: String
    let createdAt: Date

    init(score: Int, avatarId: String, createdAt: Date) {
        self.id = UUID()
        self.score = score
        self.avatarId = avatarId
        self.createdAt = createdAt
    }
}
