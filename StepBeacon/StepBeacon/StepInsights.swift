import Foundation

enum StepInsights {
    static func summary(for activities: [DayActivity], goal: Int) -> InsightSummary {
        InsightSummary(
            currentStreak: currentStreak(in: activities, goal: goal),
            averageSteps: averageSteps(in: activities),
            bestDay: bestDay(in: activities),
            goalHitCount: goalHitCount(in: activities, goal: goal),
            totalDistanceMeters: activities.reduce(0) { $0 + $1.distanceMeters },
            totalFloors: activities.reduce(0) { $0 + $1.floorsAscended },
            weeklyTrendDelta: weeklyTrendDelta(in: activities)
        )
    }

    static func averageSteps(in activities: [DayActivity]) -> Int {
        guard !activities.isEmpty else { return 0 }
        return activities.map(\.steps).reduce(0, +) / activities.count
    }

    static func bestDay(in activities: [DayActivity]) -> DayActivity? {
        activities.max(by: { $0.steps < $1.steps })
    }

    static func goalHitCount(in activities: [DayActivity], goal: Int) -> Int {
        activities.filter { $0.steps >= goal }.count
    }

    static func currentStreak(in activities: [DayActivity], goal: Int) -> Int {
        guard !activities.isEmpty else { return 0 }

        var streak = 0
        for day in activities.sorted(by: { $0.date > $1.date }) {
            guard day.steps >= goal else { break }
            streak += 1
        }
        return streak
    }

    static func weeklyTrendDelta(in activities: [DayActivity]) -> Int {
        let sorted = activities.sorted(by: { $0.date < $1.date })
        let recent = Array(sorted.suffix(7))
        let previous = Array(sorted.dropLast(min(7, sorted.count)).suffix(7))
        guard !recent.isEmpty, !previous.isEmpty else { return 0 }
        return averageSteps(in: recent) - averageSteps(in: previous)
    }

    static func weekdayAverages(from activities: [DayActivity]) -> [WeekdayAverage] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: activities) { calendar.component(.weekday, from: $0.date) }

        return calendar.veryShortWeekdaySymbols.enumerated().map { index, label in
            let weekday = index + 1
            let days = grouped[weekday] ?? []
            let average = days.isEmpty ? 0 : averageSteps(in: days)
            return WeekdayAverage(label: label, averageSteps: average)
        }
    }
}
