import Foundation

@MainActor
final class ActivityStore: ObservableObject {
    @Published private(set) var days: [DayActivity] = []
    @Published private(set) var authorizationState: MotionAuthorizationState = .unknown
    @Published private(set) var dataSource: ActivityDataSource = .unavailable
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var isLoading = false

    private let provider = StepDataProvider()
    private let motionAccess = MotionAccessManager()
    private var hasStartedLiveUpdates = false

    var today: DayActivity {
        days.last ?? DayActivity.empty(on: .now)
    }

    func bootstrap(using settings: SettingsStore) async {
        if days.isEmpty {
            await refresh(using: settings)
        } else {
            startLiveUpdatesIfNeeded(using: settings)
        }
    }

    func refresh(using settings: SettingsStore) async {
        isLoading = true
        motionAccess.refreshStatus()

        let timeline = await provider.loadRecentDays(limit: 30, useDemoData: settings.prefersDemoData)
        days = timeline.days
        dataSource = timeline.source
        authorizationState = timeline.authorizationState
        lastSyncDate = .now
        isLoading = false

        startLiveUpdatesIfNeeded(using: settings)
    }

    func requestAccess(using settings: SettingsStore) async {
        _ = await provider.requestAccess()
        motionAccess.refreshStatus()
        authorizationState = motionAccess.authorizationState
        await refresh(using: settings)
    }

    func activities(for range: TrendRange) -> [DayActivity] {
        Array(days.suffix(range.dayCount))
    }

    func shareText(goal: Int, distanceUnit: DistanceUnitPreference) -> String {
        let summary = StepInsights.summary(for: days, goal: goal)
        let todayDistance = distanceUnit.convert(distanceMeters: today.distanceMeters)
        let distanceText = todayDistance.formatted(
            .number.precision(todayDistance >= 10 ? .fractionLength(0) : .fractionLength(1))
        )

        return """
        StepBeacon today:
        • \(today.steps.formatted()) steps
        • \(distanceText) \(distanceUnit.symbol)
        • \(today.floorsAscended) floors
        • streak: \(summary.currentStreak) days
        • goal progress: \(min(today.steps * 100 / max(goal, 1), 999))%
        """
    }

    func stopLiveUpdates() {
        provider.stopLiveUpdates()
        hasStartedLiveUpdates = false
    }

    private func startLiveUpdatesIfNeeded(using settings: SettingsStore) {
        guard dataSource == .live else { return }
        guard !settings.prefersDemoData else { return }
        guard !hasStartedLiveUpdates else { return }

        hasStartedLiveUpdates = true
        provider.startLiveUpdates { [weak self] liveToday in
            self?.merge(today: liveToday)
        }
    }

    private func merge(today liveToday: DayActivity) {
        if let index = days.lastIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: liveToday.date) }) {
            days[index] = liveToday
        } else {
            days.append(liveToday)
        }
        lastSyncDate = .now
    }
}
