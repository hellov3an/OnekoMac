import Foundation
import Combine

// MARK: – Check context

struct AchievementContext {
    let stats: CatStats
    let laserActive: Bool
    let scale: Float
    let speedMultiplier: Float
    let dockedLongEnough: Bool   // docked >= 60 min without waking
    let hourOfDay: Int           // 0-23
}

// MARK: – Manager

final class AchievementManager: ObservableObject {
    /// IDs of unlocked achievements.
    @Published private(set) var unlockedIDs: Set<String> = []
    /// Timestamps keyed by achievement ID.
    @Published private(set) var unlockedDates: [String: Date] = [:]

    /// Fires once per newly unlocked achievement.
    let unlockPublisher = PassthroughSubject<Achievement, Never>()

    private let defaults   = UserDefaults.standard
    private let storeKey   = "unlocked_achievements_v2"

    init() {
        if let dict = defaults.dictionary(forKey: storeKey) as? [String: Double] {
            unlockedDates = dict.mapValues { Date(timeIntervalSince1970: $0) }
            unlockedIDs   = Set(dict.keys)
        } else {
            // Migrate from old format (string array)
            let old = defaults.stringArray(forKey: "unlocked_achievements") ?? []
            unlockedIDs = Set(old)
        }
    }

    var unlocked: [Achievement] { allAchievements.filter { unlockedIDs.contains($0.id) } }

    // MARK: – Check

    func check(context: AchievementContext) {
        let s = context.stats
        let m = s.distanceMeters

        // Explorer
        eval("first_step",     m > 0)
        eval("hundred_meters", m >= 100)
        eval("one_km",         m >= 1_000)
        eval("ten_km",         m >= 10_000)
        eval("hundred_km",     m >= 100_000)
        eval("speed_demon",    context.speedMultiplier >= 2.4)
        eval("slow_life",      context.speedMultiplier <= 0.41)

        // Sleeper
        eval("nap_10",         s.naps >= 10)
        eval("nap_100",        s.naps >= 100)
        eval("nap_1000",       s.naps >= 1_000)
        eval("docked_first",   s.dockedCount >= 1)
        eval("docked_long",    context.dockedLongEnough)

        // Chaos
        eval("scratch_10",     s.scratches >= 10)
        eval("scratch_100",    s.scratches >= 100)
        eval("scratch_1000",   s.scratches >= 1_000)
        eval("giant_cat",      context.scale >= 2.99)
        eval("tiny_cat",       context.scale <= 0.51)

        // Loyal
        eval("streak_7",       s.streak >= 7)
        eval("streak_30",      s.streak >= 30)
        eval("streak_100",     s.streak >= 100)
        eval("two_weeks",      s.daysTogether >= 14)
        eval("birthday",       s.daysTogether >= 365)

        // Play
        eval("laser",          context.laserActive || s.laserSessions >= 1)
        eval("circus_act",     context.laserActive && context.speedMultiplier >= 2.4)
        eval("all_skins",      SkinManager.skinIDs.allSatisfy { s.usedSkinIDs.contains($0) })
        eval("level_5",        s.level >= 5)
        eval("level_10",       s.level >= 10)

        // Secret
        eval("early_bird",     context.hourOfDay < 7)
        eval("night_owl",      context.hourOfDay >= 2 && context.hourOfDay < 4)
        eval("level_20",       s.level >= 20)
        eval("laser_100",      s.laserSessions >= 100)
    }

    /// Call when the user discovers the settings easter egg.
    func triggerEasterEgg() { eval("easter_egg", true) }

    // MARK: – Private

    private func eval(_ id: String, _ condition: Bool) {
        guard condition, !unlockedIDs.contains(id) else { return }
        let now = Date()
        unlockedIDs.insert(id)
        unlockedDates[id] = now
        persist()
        guard let a = allAchievements.first(where: { $0.id == id }) else { return }
        unlockPublisher.send(a)
    }

    private func persist() {
        let dict = unlockedDates.mapValues { $0.timeIntervalSince1970 }
        defaults.set(dict, forKey: storeKey)
    }
}
