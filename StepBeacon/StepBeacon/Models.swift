import Foundation

enum AppTab: String {
    case today
    case trends
    case settings
}

enum TrendRange: String, CaseIterable, Identifiable {
    case week = "7D"
    case month = "30D"
    case quarter = "90D"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .quarter:
            return "Quarter"
        }
    }

    var dayCount: Int {
        switch self {
        case .week:
            return 7
        case .month:
            return 30
        case .quarter:
            return 90
        }
    }
}

enum DistanceUnitPreference: String, CaseIterable, Codable, Identifiable {
    case automatic
    case miles
    case kilometers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .miles:
            return "Miles"
        case .kilometers:
            return "Kilometers"
        }
    }

    var symbol: String {
        resolvedUnit == .miles ? "mi" : "km"
    }

    private var resolvedUnit: DistanceUnitPreference {
        if self != .automatic {
            return self
        }

        let usesMetric = Locale.current.usesMetricSystem
        return usesMetric ? .kilometers : .miles
    }

    func convert(distanceMeters: Double) -> Double {
        switch resolvedUnit {
        case .miles:
            return distanceMeters / 1_609.344
        case .kilometers, .automatic:
            return distanceMeters / 1_000
        }
    }
}

enum MotionAuthorizationState: String {
    case unknown
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable

    var title: String {
        switch self {
        case .unknown:
            return "Checking motion access"
        case .notDetermined:
            return "Motion access needed"
        case .authorized:
            return "Motion access enabled"
        case .denied:
            return "Motion access denied"
        case .restricted:
            return "Motion access restricted"
        case .unavailable:
            return "Motion tracking unavailable"
        }
    }

    var guidance: String {
        switch self {
        case .unknown:
            return "StepBeacon is getting your walking permissions ready."
        case .notDetermined:
            return "Allow Motion & Fitness access so StepBeacon can read your daily steps, distance, and stairs."
        case .authorized:
            return "Live step totals are available on this device."
        case .denied:
            return "Turn Motion & Fitness back on in Settings to load live step history."
        case .restricted:
            return "This device does not allow Motion & Fitness access for StepBeacon."
        case .unavailable:
            return "This environment cannot provide live pedometer data, so StepBeacon will use demo activity instead."
        }
    }

    var canRequestAccess: Bool {
        self == .notDetermined
    }
}

enum ActivityDataSource: String {
    case live
    case demo
    case unavailable

    var label: String {
        switch self {
        case .live:
            return "Live device data"
        case .demo:
            return "Demo activity"
        case .unavailable:
            return "No motion data"
        }
    }
}

struct DayActivity: Identifiable, Codable, Equatable {
    let date: Date
    var steps: Int
    var distanceMeters: Double
    var floorsAscended: Int
    var averageActivePaceSecondsPerMeter: Double?

    var id: Date { date }

    var isGoalReady: Bool {
        steps > 0 || distanceMeters > 0 || floorsAscended > 0
    }

    static func empty(on date: Date) -> DayActivity {
        DayActivity(
            date: Calendar.current.startOfDay(for: date),
            steps: 0,
            distanceMeters: 0,
            floorsAscended: 0,
            averageActivePaceSecondsPerMeter: nil
        )
    }
}

struct InsightSummary: Equatable {
    var currentStreak: Int
    var averageSteps: Int
    var bestDay: DayActivity?
    var goalHitCount: Int
    var totalDistanceMeters: Double
    var totalFloors: Int
    var weeklyTrendDelta: Int
}

struct WeekdayAverage: Identifiable, Equatable {
    let label: String
    let averageSteps: Int

    var id: String { label }
}

enum AchievementKind: String, CaseIterable, Codable {
    case firstWalk
    case goalBreaker
    case tenKDay
    case streak3
    case streak7
    case climb50
    case distance25K
    case weekendWin
}

struct AchievementDefinition: Identifiable, Equatable {
    let kind: AchievementKind
    let title: String
    let subtitle: String
    let systemImage: String

    var id: String { kind.rawValue }
}

struct AchievementStatus: Identifiable, Equatable {
    let definition: AchievementDefinition
    let unlockedDate: Date?

    var id: String { definition.id }
    var isUnlocked: Bool { unlockedDate != nil }
}

extension Calendar {
    func recentDays(count: Int, endingAt date: Date = .now) -> [Date] {
        let today = startOfDay(for: date)
        return (0..<count).compactMap { offset in
            self.date(byAdding: .day, value: offset - (count - 1), to: today)
        }
    }
}

extension Date {
    var monthDayLabel: String {
        formatted(.dateTime.month(.abbreviated).day())
    }
}
