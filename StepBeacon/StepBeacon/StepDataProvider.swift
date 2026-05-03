import CoreMotion
import Foundation

struct StepTimeline {
    var days: [DayActivity]
    var source: ActivityDataSource
    var authorizationState: MotionAuthorizationState
}

@MainActor
final class StepDataProvider {
    private let pedometer = CMPedometer()
    private let calendar = Calendar.current

    func requestAccess() async -> MotionAuthorizationState {
        if AppLaunchConfiguration.shouldAlwaysUseDemoData {
            return .authorized
        }

        guard CMPedometer.isStepCountingAvailable() else {
            return .unavailable
        }

        let end = Date()
        let start = calendar.date(byAdding: .hour, value: -1, to: end) ?? end
        _ = await query(from: start, to: end)
        return MotionAccessManager.currentState()
    }

    func loadRecentDays(limit: Int, useDemoData: Bool) async -> StepTimeline {
        if useDemoData || AppLaunchConfiguration.shouldAlwaysUseDemoData {
            return StepTimeline(
                days: Array(AppLaunchConfiguration.seededActivities.suffix(limit)),
                source: .demo,
                authorizationState: .authorized
            )
        }

        guard CMPedometer.isStepCountingAvailable() else {
            return StepTimeline(days: [], source: .unavailable, authorizationState: .unavailable)
        }

        let requestedDays = calendar.recentDays(count: limit)
        var results: [DayActivity] = []

        for date in requestedDays {
            results.append(await queryDay(containing: date))
        }

        let finalState = MotionAccessManager.currentState()
        let source: ActivityDataSource = results.contains(where: \.isGoalReady) ? .live : .unavailable
        return StepTimeline(days: results, source: source, authorizationState: finalState)
    }

    func startLiveUpdates(handler: @escaping @MainActor (DayActivity) -> Void) {
        guard !AppLaunchConfiguration.shouldAlwaysUseDemoData else { return }
        guard CMPedometer.isStepCountingAvailable() else { return }

        let startOfDay = calendar.startOfDay(for: .now)
        pedometer.startUpdates(from: startOfDay) { [weak self] data, _ in
            guard let self else { return }
            let updated = self.makeDayActivity(from: data, for: startOfDay)
            Task { @MainActor in
                handler(updated)
            }
        }
    }

    func stopLiveUpdates() {
        pedometer.stopUpdates()
    }

    private func queryDay(containing date: Date) async -> DayActivity {
        let start = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: start) ?? .now
        let end = min(nextDay, .now)
        let data = await query(from: start, to: end)
        return makeDayActivity(from: data, for: start)
    }

    private func query(from start: Date, to end: Date) async -> CMPedometerData? {
        await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: end) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }

    private func makeDayActivity(from data: CMPedometerData?, for date: Date) -> DayActivity {
        DayActivity(
            date: calendar.startOfDay(for: date),
            steps: data?.numberOfSteps.intValue ?? 0,
            distanceMeters: data?.distance?.doubleValue ?? 0,
            floorsAscended: data?.floorsAscended?.intValue ?? 0,
            averageActivePaceSecondsPerMeter: data?.averageActivePace?.doubleValue
        )
    }
}
