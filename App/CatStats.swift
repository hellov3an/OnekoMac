import Foundation
import os.lock

/// Persistent lifetime stats for the cat.
/// Thread-safe: addDistance/recordNap/recordScratch may be called from any thread.
final class CatStats: ObservableObject {
    private enum Key {
        static let distance      = "cat_stat_distance_pts"
        static let naps          = "cat_stat_naps"
        static let scratches     = "cat_stat_scratches"
        static let firstLaunch   = "cat_stat_first_launch"
        static let streak        = "cat_streak"
        static let streakDate    = "cat_streak_last_date"
        static let dockedCount   = "cat_stat_docked_count"
        static let laserSessions = "cat_stat_laser_sessions"
        static let skinsUsed     = "cat_stat_skins_used"
    }

    @Published private(set) var distancePoints: Double
    @Published private(set) var naps: Int
    @Published private(set) var scratches: Int
    @Published private(set) var streak: Int = 1
    @Published private(set) var dockedCount: Int = 0
    @Published private(set) var laserSessions: Int = 0
    @Published private(set) var usedSkinIDs: Set<String> = []
    let firstLaunchDate: Date

    private var pendingDistance: Double = 0
    private var _lock = os_unfair_lock()
    private let defaults = UserDefaults.standard

    init() {
        distancePoints = defaults.double(forKey: Key.distance)
        naps           = defaults.integer(forKey: Key.naps)
        scratches      = defaults.integer(forKey: Key.scratches)
        dockedCount    = defaults.integer(forKey: Key.dockedCount)
        laserSessions  = defaults.integer(forKey: Key.laserSessions)
        usedSkinIDs    = Set(defaults.stringArray(forKey: Key.skinsUsed) ?? [])

        if let t = defaults.object(forKey: Key.firstLaunch) as? Double {
            firstLaunchDate = Date(timeIntervalSince1970: t)
        } else {
            let now = Date()
            firstLaunchDate = now
            defaults.set(now.timeIntervalSince1970, forKey: Key.firstLaunch)
        }

        updateStreak()

        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.flush()
        }
    }

    // MARK: – Write (render thread safe)

    func addDistance(_ pts: Float) {
        os_unfair_lock_lock(&_lock)
        pendingDistance += Double(pts)
        os_unfair_lock_unlock(&_lock)
    }

    func recordNap() {
        DispatchQueue.main.async {
            self.naps += 1
            self.defaults.set(self.naps, forKey: Key.naps)
        }
    }

    func recordScratch() {
        DispatchQueue.main.async {
            self.scratches += 1
            self.defaults.set(self.scratches, forKey: Key.scratches)
        }
    }

    func recordDocked() {
        DispatchQueue.main.async {
            self.dockedCount += 1
            self.defaults.set(self.dockedCount, forKey: Key.dockedCount)
        }
    }

    func recordLaserSession() {
        DispatchQueue.main.async {
            self.laserSessions += 1
            self.defaults.set(self.laserSessions, forKey: Key.laserSessions)
        }
    }

    func recordSkinUsed(_ id: String) {
        DispatchQueue.main.async {
            guard !self.usedSkinIDs.contains(id) else { return }
            self.usedSkinIDs.insert(id)
            self.defaults.set(Array(self.usedSkinIDs), forKey: Key.skinsUsed)
        }
    }

    func reset() {
        os_unfair_lock_lock(&_lock); pendingDistance = 0; os_unfair_lock_unlock(&_lock)
        distancePoints = 0; naps = 0; scratches = 0; dockedCount = 0; laserSessions = 0
        usedSkinIDs = []
        defaults.removeObject(forKey: Key.distance)
        defaults.removeObject(forKey: Key.naps)
        defaults.removeObject(forKey: Key.scratches)
        defaults.removeObject(forKey: Key.dockedCount)
        defaults.removeObject(forKey: Key.laserSessions)
        defaults.removeObject(forKey: Key.skinsUsed)
    }

    // MARK: – Streak

    private func updateStreak() {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        let saved = defaults.integer(forKey: Key.streak)

        if let ts = defaults.object(forKey: Key.streakDate) as? Double {
            let last = cal.startOfDay(for: Date(timeIntervalSince1970: ts))
            let diff = cal.dateComponents([.day], from: last, to: today).day ?? 0
            switch diff {
            case 0:  streak = max(1, saved)
            case 1:  streak = saved + 1
            default: streak = 1
            }
        } else {
            streak = 1
        }

        defaults.set(today.timeIntervalSince1970, forKey: Key.streakDate)
        defaults.set(streak, forKey: Key.streak)
    }

    // MARK: – Level / XP

    /// 1 logical point ≈ 0.27 mm at ~94 logical PPI.
    var distanceMeters: Double { distancePoints * 0.000_27 }

    /// Level = floor(sqrt(meters / 2.5)) + 1  (level 2 at ~2.5 m, level 10 at ~202 m)
    var level: Int { Int(sqrt(distanceMeters / 2.5)) + 1 }

    /// Progress within current level [0, 1).
    var xpProgress: Double {
        let n    = Double(level - 1)
        let prev = n * n * 2.5
        let next = (n + 1) * (n + 1) * 2.5
        guard next > prev else { return 1 }
        return min(1, (distanceMeters - prev) / (next - prev))
    }

    /// Meters remaining until the next level-up.
    var metersToNextLevel: Double {
        let n = Double(level)
        return max(0, n * n * 2.5 - distanceMeters)
    }

    /// Short label for the XP bar: "12m / 40m"
    var xpLabel: String {
        let n    = Double(level - 1)
        let next = Int((n + 1) * (n + 1) * 2.5)
        return "\(Int(distanceMeters))m / \(next)m"
    }

    var daysTogether: Int {
        Calendar.current.dateComponents([.day], from: firstLaunchDate, to: .now).day ?? 0
    }

    // MARK: – Private

    private func flush() {
        os_unfair_lock_lock(&_lock)
        let d = pendingDistance
        pendingDistance = 0
        os_unfair_lock_unlock(&_lock)
        guard d > 0 else { return }
        distancePoints += d
        defaults.set(distancePoints, forKey: Key.distance)
    }
}
