import Foundation
import Combine

final class AchievementManager: ObservableObject {
    @Published private(set) var unlockedIDs: Set<String>

    /// Fires once per newly unlocked achievement — subscribe to drive the toast notification.
    let unlockPublisher = PassthroughSubject<Achievement, Never>()

    private let defaults = UserDefaults.standard
    private let storeKey = "unlocked_achievements"

    init() {
        let stored = defaults.stringArray(forKey: storeKey) ?? []
        unlockedIDs = Set(stored)
    }

    var unlocked: [Achievement] { allAchievements.filter { unlockedIDs.contains($0.id) } }

    /// Call this from the main thread whenever relevant state changes.
    func check(stats: CatStats, laserActive: Bool, scale: Float, speedMultiplier: Float) {
        let m = stats.distanceMeters
        eval("first_step",     m > 0)
        eval("hundred_meters", m >= 100)
        eval("one_km",         m >= 1_000)
        eval("ten_km",         m >= 10_000)
        eval("nap_10",         stats.naps >= 10)
        eval("nap_100",        stats.naps >= 100)
        eval("scratch_10",     stats.scratches >= 10)
        eval("scratch_100",    stats.scratches >= 100)
        eval("streak_7",       stats.streak >= 7)
        eval("streak_30",      stats.streak >= 30)
        eval("laser",          laserActive)
        eval("level_5",        stats.level >= 5)
        eval("level_10",       stats.level >= 10)
        eval("giant_cat",      scale >= 2.99)
        eval("speed_hyper",    speedMultiplier >= 2.4)
    }

    private func eval(_ id: String, _ condition: Bool) {
        guard condition, !unlockedIDs.contains(id) else { return }
        unlockedIDs.insert(id)
        defaults.set(Array(unlockedIDs), forKey: storeKey)
        guard let a = allAchievements.first(where: { $0.id == id }) else { return }
        unlockPublisher.send(a)
    }
}
