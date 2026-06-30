import Foundation
import os.lock

/// Persistent lifetime stats for the cat.
/// Thread-safe: addDistance/recordNap/recordScratch may be called from any thread.
final class CatStats: ObservableObject {
    private enum Key {
        static let distance    = "cat_stat_distance_pts"
        static let naps        = "cat_stat_naps"
        static let scratches   = "cat_stat_scratches"
        static let firstLaunch = "cat_stat_first_launch"
    }

    @Published private(set) var distancePoints: Double
    @Published private(set) var naps: Int
    @Published private(set) var scratches: Int
    let firstLaunchDate: Date

    private var pendingDistance: Double = 0
    private var _lock = os_unfair_lock()
    private let defaults = UserDefaults.standard

    init() {
        distancePoints = defaults.double(forKey: Key.distance)
        naps           = defaults.integer(forKey: Key.naps)
        scratches      = defaults.integer(forKey: Key.scratches)

        if let t = defaults.object(forKey: Key.firstLaunch) as? Double {
            firstLaunchDate = Date(timeIntervalSince1970: t)
        } else {
            let now = Date()
            firstLaunchDate = now
            defaults.set(now.timeIntervalSince1970, forKey: Key.firstLaunch)
        }

        // Flush accumulated walk distance to disk every 30 s.
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

    func reset() {
        os_unfair_lock_lock(&_lock); pendingDistance = 0; os_unfair_lock_unlock(&_lock)
        distancePoints = 0; naps = 0; scratches = 0
        defaults.removeObject(forKey: Key.distance)
        defaults.removeObject(forKey: Key.naps)
        defaults.removeObject(forKey: Key.scratches)
    }

    // MARK: – Display helpers

    /// 1 logical point ≈ 0.27 mm at ~94 logical PPI (MacBook Retina @2x = 188 native PPI).
    var distanceMeters: Double { distancePoints * 0.000_27 }

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
