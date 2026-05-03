import Foundation

enum AchievementEngine {
    static let definitions: [AchievementDefinition] = [
        AchievementDefinition(
            kind: .firstWalk,
            title: "First Walk",
            subtitle: "Log 1,000 steps in a single day.",
            systemImage: "figure.walk"
        ),
        AchievementDefinition(
            kind: .goalBreaker,
            title: "Goal Breaker",
            subtitle: "Hit your daily goal once.",
            systemImage: "target"
        ),
        AchievementDefinition(
            kind: .tenKDay,
            title: "10K Day",
            subtitle: "Reach 10,000 steps in one day.",
            systemImage: "figure.walk.motion"
        ),
        AchievementDefinition(
            kind: .streak3,
            title: "3-Day Streak",
            subtitle: "Beat your goal three days in a row.",
            systemImage: "flame"
        ),
        AchievementDefinition(
            kind: .streak7,
            title: "7-Day Streak",
            subtitle: "Keep your streak rolling for a full week.",
            systemImage: "flame.fill"
        ),
        AchievementDefinition(
            kind: .climb50,
            title: "Stair Climber",
            subtitle: "Climb 50 floors total.",
            systemImage: "stairs"
        ),
        AchievementDefinition(
            kind: .distance25K,
            title: "Distance Explorer",
            subtitle: "Cover 25 kilometers in total.",
            systemImage: "map"
        ),
        AchievementDefinition(
            kind: .weekendWin,
            title: "Weekend Win",
            subtitle: "Hit your goal on a Saturday or Sunday.",
            systemImage: "sun.max"
        )
    ]

    static func statuses(for activities: [DayActivity], goal: Int) -> [AchievementStatus] {
        definitions.map { definition in
            AchievementStatus(
                definition: definition,
                unlockedDate: unlockedDate(for: definition.kind, in: activities, goal: goal)
            )
        }
    }

    private static func unlockedDate(
        for kind: AchievementKind,
        in activities: [DayActivity],
        goal: Int
    ) -> Date? {
        let sorted = activities.sorted(by: { $0.date < $1.date })
        let calendar = Calendar.current

        switch kind {
        case .firstWalk:
            return sorted.first(where: { $0.steps >= 1_000 })?.date
        case .goalBreaker:
            return sorted.first(where: { $0.steps >= goal })?.date
        case .tenKDay:
            return sorted.first(where: { $0.steps >= 10_000 })?.date
        case .streak3:
            return streakUnlockDate(requiredLength: 3, in: sorted, goal: goal)
        case .streak7:
            return streakUnlockDate(requiredLength: 7, in: sorted, goal: goal)
        case .climb50:
            var runningTotal = 0
            for day in sorted {
                runningTotal += day.floorsAscended
                if runningTotal >= 50 { return day.date }
            }
            return nil
        case .distance25K:
            var runningDistance = 0.0
            for day in sorted {
                runningDistance += day.distanceMeters
                if runningDistance >= 25_000 { return day.date }
            }
            return nil
        case .weekendWin:
            return sorted.first(where: {
                let weekday = calendar.component(.weekday, from: $0.date)
                return (weekday == 1 || weekday == 7) && $0.steps >= goal
            })?.date
        }
    }

    private static func streakUnlockDate(requiredLength: Int, in activities: [DayActivity], goal: Int) -> Date? {
        var streak = 0
        for day in activities {
            if day.steps >= goal {
                streak += 1
                if streak >= requiredLength {
                    return day.date
                }
            } else {
                streak = 0
            }
        }

        return nil
    }
}
