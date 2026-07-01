import Foundation

struct Achievement: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let description: String
}

let allAchievements: [Achievement] = [
    Achievement(id: "first_step",     icon: "🐾", title: "First Step",      description: "Your cat started walking"),
    Achievement(id: "hundred_meters", icon: "🌙", title: "Night Walker",    description: "100 meters walked"),
    Achievement(id: "one_km",         icon: "🏅", title: "Kilometer Club",  description: "1 km walked"),
    Achievement(id: "ten_km",         icon: "🏆", title: "Marathon Cat",    description: "10 km walked"),
    Achievement(id: "nap_10",         icon: "😴", title: "Nap Champion",    description: "10 naps taken"),
    Achievement(id: "nap_100",        icon: "💤", title: "Sleepyhead",      description: "100 naps taken"),
    Achievement(id: "scratch_10",     icon: "🐱", title: "Scratcher",       description: "10 scratches"),
    Achievement(id: "scratch_100",    icon: "💥", title: "Wall Destroyer",  description: "100 scratches"),
    Achievement(id: "streak_7",       icon: "🔥", title: "Loyal",           description: "7-day streak"),
    Achievement(id: "streak_30",      icon: "♾️", title: "Devoted",         description: "30-day streak"),
    Achievement(id: "laser",          icon: "🔴", title: "Laser Enthusiast",description: "Used the laser pointer"),
    Achievement(id: "level_5",        icon: "⭐", title: "Leveling Up",     description: "Reached level 5"),
    Achievement(id: "level_10",       icon: "🌟", title: "Veteran",         description: "Reached level 10"),
    Achievement(id: "giant_cat",      icon: "🐉", title: "Kaiju Cat",       description: "Set cat size to 3×"),
    Achievement(id: "speed_hyper",    icon: "⚡", title: "Speed Demon",     description: "Activated Hyper speed"),
]
