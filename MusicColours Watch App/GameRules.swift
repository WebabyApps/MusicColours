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

    func load() -> [Int] {
        return defaults.array(forKey: key) as? [Int] ?? []
    }

    @discardableResult
    func record(_ value: Int) -> [Int] {
        var updated = load()
        updated.append(value)
        if updated.count > limit { updated = Array(updated.suffix(limit)) }
        defaults.set(updated, forKey: key)
        return updated
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}
