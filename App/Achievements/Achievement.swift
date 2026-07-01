import Foundation

// MARK: – Category

enum AchievementCategory: String, CaseIterable, Identifiable {
    case explorer, sleeper, chaos, loyal, play, secret
    var id: String { rawValue }

    var label: String {
        switch self {
        case .explorer: "🗺️ Explorer"
        case .sleeper:  "😴 Sleeper"
        case .chaos:    "💥 Chaos"
        case .loyal:    "🔥 Loyal"
        case .play:     "🎮 Play"
        case .secret:   "🔒 Secret"
        }
    }
}

// MARK: – Model

struct Achievement: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let category: AchievementCategory
    let isSecret: Bool
}

// MARK: – All 32 achievements

let allAchievements: [Achievement] = [

    // ── Explorer ─────────────────────────────────────────────────────────────
    Achievement(id: "first_step",     icon: "🐾", title: "First Step",
                description: "Your cat started walking",            category: .explorer, isSecret: false),
    Achievement(id: "hundred_meters", icon: "🌙", title: "Night Walker",
                description: "Walked 100 meters",                   category: .explorer, isSecret: false),
    Achievement(id: "one_km",         icon: "🏅", title: "Kilometer Club",
                description: "Walked 1 kilometer",                  category: .explorer, isSecret: false),
    Achievement(id: "ten_km",         icon: "🏆", title: "Marathon Cat",
                description: "Walked 10 kilometers",                category: .explorer, isSecret: false),
    Achievement(id: "hundred_km",     icon: "🌍", title: "World Tour",
                description: "Walked 100 kilometers",               category: .explorer, isSecret: true),
    Achievement(id: "speed_demon",    icon: "⚡", title: "Speed Demon",
                description: "Activated Hyper speed",               category: .explorer, isSecret: false),
    Achievement(id: "slow_life",      icon: "🐢", title: "Slow Life",
                description: "Activated Lazy mode",                 category: .explorer, isSecret: false),

    // ── Sleeper ───────────────────────────────────────────────────────────────
    Achievement(id: "nap_10",         icon: "😴", title: "Nap Champion",
                description: "10 naps taken",                       category: .sleeper, isSecret: false),
    Achievement(id: "nap_100",        icon: "💤", title: "Sleepyhead",
                description: "100 naps taken",                      category: .sleeper, isSecret: false),
    Achievement(id: "nap_1000",       icon: "🛌", title: "Comatose",
                description: "1000 naps taken",                     category: .sleeper, isSecret: true),
    Achievement(id: "docked_first",   icon: "🌙", title: "Up in the Attic",
                description: "Docked to the menu bar",              category: .sleeper, isSecret: false),
    Achievement(id: "docked_long",    icon: "❄️", title: "Cryogenic",
                description: "Stayed docked for 1 hour straight",   category: .sleeper, isSecret: true),

    // ── Chaos ─────────────────────────────────────────────────────────────────
    Achievement(id: "scratch_10",     icon: "🐱", title: "Scratcher",
                description: "10 scratches",                        category: .chaos, isSecret: false),
    Achievement(id: "scratch_100",    icon: "💥", title: "Wall Destroyer",
                description: "100 scratches",                       category: .chaos, isSecret: false),
    Achievement(id: "scratch_1000",   icon: "💀", title: "Demolition Expert",
                description: "1000 scratches",                      category: .chaos, isSecret: true),
    Achievement(id: "giant_cat",      icon: "🐉", title: "Kaiju Cat",
                description: "Set cat size to 3×",                  category: .chaos, isSecret: false),
    Achievement(id: "tiny_cat",       icon: "🔬", title: "Quantum Cat",
                description: "Set cat size to 0.5×",               category: .chaos, isSecret: true),

    // ── Loyal ─────────────────────────────────────────────────────────────────
    Achievement(id: "streak_7",       icon: "🔥", title: "Loyal",
                description: "7-day streak",                        category: .loyal, isSecret: false),
    Achievement(id: "streak_30",      icon: "♾️", title: "Devoted",
                description: "30-day streak",                       category: .loyal, isSecret: false),
    Achievement(id: "streak_100",     icon: "💎", title: "Inseparable",
                description: "100-day streak",                      category: .loyal, isSecret: true),
    Achievement(id: "two_weeks",      icon: "🗓️", title: "Two Weeks In",
                description: "14 days since adoption",              category: .loyal, isSecret: false),
    Achievement(id: "birthday",       icon: "🎂", title: "Happy Birthday!",
                description: "1 year since adoption",               category: .loyal, isSecret: true),

    // ── Play ──────────────────────────────────────────────────────────────────
    Achievement(id: "laser",          icon: "🔴", title: "Laser Enthusiast",
                description: "Used the laser pointer",              category: .play, isSecret: false),
    Achievement(id: "circus_act",     icon: "🎪", title: "Circus Act",
                description: "Laser + Hyper speed simultaneously",  category: .play,     isSecret: true),
    Achievement(id: "all_skins",      icon: "🎨", title: "Fashionista",
                description: "Tried every bundled skin",            category: .play, isSecret: false),
    Achievement(id: "level_5",        icon: "⭐", title: "Leveling Up",
                description: "Reached level 5",                     category: .play, isSecret: false),
    Achievement(id: "level_10",       icon: "🌟", title: "Veteran",
                description: "Reached level 10",                    category: .play, isSecret: false),

    // ── Secret ────────────────────────────────────────────────────────────────
    Achievement(id: "early_bird",     icon: "🌅", title: "Early Bird",
                description: "Used the app before 7 AM",           category: .secret, isSecret: true),
    Achievement(id: "night_owl",      icon: "🦉", title: "Night Owl",
                description: "Used the app between 2–4 AM",        category: .secret, isSecret: true),
    Achievement(id: "level_20",       icon: "👑", title: "Legend",
                description: "Reached level 20",                    category: .secret, isSecret: true),
    Achievement(id: "laser_100",      icon: "🔴", title: "Red Obsession",
                description: "Used the laser pointer 100 times",   category: .secret, isSecret: true),
    Achievement(id: "easter_egg",     icon: "🥚", title: "I Found It",
                description: "Discovered the hidden easter egg",    category: .secret, isSecret: true),
]
