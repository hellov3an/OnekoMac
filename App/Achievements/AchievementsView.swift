import SwiftUI

// MARK: – Category pill

private struct CategoryPill: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? .white : Color.white.opacity(0.45))
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(
                    selected ? Color.orange.opacity(0.22) : Color.white.opacity(0.05),
                    in: Capsule()
                )
                .overlay(Capsule().strokeBorder(
                    selected ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: – Achievement card

private struct AchievementCard: View {
    let achievement: Achievement
    let unlocked: Bool
    let unlockedAt: Date?

    // Secret + locked → show "???"
    private var revealed: Bool { unlocked || !achievement.isSecret }

    var body: some View {
        VStack(spacing: 6) {
            Text(unlocked ? achievement.icon : (achievement.isSecret ? "🔒" : achievement.icon))
                .font(.system(size: 30))
                .opacity(unlocked ? 1 : 0.25)
                .padding(.top, 4)

            Text(revealed ? achievement.title : "???")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(unlocked ? .white : Color.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Group {
                if unlocked, let date = unlockedAt {
                    Text(date.formatted(.dateTime.day().month(.abbreviated).year()))
                        .foregroundStyle(Color.orange.opacity(0.75))
                } else {
                    Text(revealed ? achievement.description : "Secret achievement")
                        .foregroundStyle(Color.white.opacity(0.22))
                        .lineLimit(2)
                }
            }
            .font(.system(size: 9))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            unlocked ? Color.orange.opacity(0.10) : Color.white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    unlocked ? Color.orange.opacity(0.28) : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
    }
}

// MARK: – Main achievements view

struct AchievementsView: View {
    @ObservedObject var manager: AchievementManager
    @State private var filter: AchievementCategory? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var displayed: [Achievement] {
        guard let f = filter else { return allAchievements }
        return allAchievements.filter { $0.category == f }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            categoryBar
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(displayed) { a in
                        AchievementCard(
                            achievement: a,
                            unlocked:    manager.unlockedIDs.contains(a.id),
                            unlockedAt:  manager.unlockedDates[a.id]
                        )
                    }
                }
                .padding(14)
            }
        }
        .frame(width: 420)
        .background(Color(red: 0.055, green: 0.055, blue: 0.11))
        .colorScheme(.dark)
    }

    // MARK: – Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ACHIEVEMENTS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.orange.opacity(0.8))
                    Text("\(manager.unlockedIDs.count) of \(allAchievements.count) unlocked")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                Spacer()
                // Trophy ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 4)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: CGFloat(manager.unlockedIDs.count) / CGFloat(allAchievements.count))
                        .stroke(
                            LinearGradient(colors: [.orange, Color(red: 1, green: 0.4, blue: 0.6)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.6), value: manager.unlockedIDs.count)
                    Text("🏆")
                        .font(.title3)
                }
            }

            // Progress bar
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.07))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.orange, Color(red: 1, green: 0.4, blue: 0.6)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(6, g.size.width
                               * CGFloat(manager.unlockedIDs.count)
                               / CGFloat(max(1, allAchievements.count))))
                        .animation(.easeInOut(duration: 0.5), value: manager.unlockedIDs.count)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }

    // MARK: – Category bar

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                CategoryPill(label: "All",  selected: filter == nil) { filter = nil }
                ForEach(AchievementCategory.allCases) { cat in
                    CategoryPill(label: cat.label, selected: filter == cat) { filter = cat }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }
}
