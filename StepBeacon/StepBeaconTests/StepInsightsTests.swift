import XCTest
@testable import StepBeacon

final class StepInsightsTests: XCTestCase {
    func testCurrentStreakStopsOnFirstMiss() {
        let activities = [
            makeDay(offsetFromToday: -2, steps: 11_000),
            makeDay(offsetFromToday: -1, steps: 10_200),
            makeDay(offsetFromToday: 0, steps: 8_900)
        ]

        XCTAssertEqual(StepInsights.currentStreak(in: activities, goal: 10_000), 0)
    }

    func testCurrentStreakCountsRecentGoalHits() {
        let activities = [
            makeDay(offsetFromToday: -2, steps: 7_000),
            makeDay(offsetFromToday: -1, steps: 11_300),
            makeDay(offsetFromToday: 0, steps: 10_050)
        ]

        XCTAssertEqual(StepInsights.currentStreak(in: activities, goal: 10_000), 2)
    }

    func testWeeklyTrendDeltaComparesRecentWeekToPreviousWeek() {
        let firstWeek = (0..<7).map { makeDay(offsetFromToday: -13 + $0, steps: 7_000) }
        let secondWeek = (0..<7).map { makeDay(offsetFromToday: -6 + $0, steps: 10_000) }

        XCTAssertEqual(StepInsights.weeklyTrendDelta(in: firstWeek + secondWeek), 3_000)
    }

    func testAchievementUnlocksGoalAndDistanceMilestones() {
        let activities = [
            makeDay(offsetFromToday: -2, steps: 10_500, distance: 8_000, floors: 20),
            makeDay(offsetFromToday: -1, steps: 11_200, distance: 9_000, floors: 18),
            makeDay(offsetFromToday: 0, steps: 12_300, distance: 9_500, floors: 15)
        ]

        let statuses = AchievementEngine.statuses(for: activities, goal: 10_000)
        XCTAssertTrue(statuses.first(where: { $0.definition.kind == .goalBreaker })?.isUnlocked == true)
        XCTAssertTrue(statuses.first(where: { $0.definition.kind == .distance25K })?.isUnlocked == true)
    }

    func testWeekdayAveragesReturnEveryWeekday() {
        let activities = [
            makeDay(offsetFromToday: -1, steps: 9_000),
            makeDay(offsetFromToday: 0, steps: 10_000)
        ]

        XCTAssertEqual(StepInsights.weekdayAverages(from: activities).count, 7)
    }

    private func makeDay(
        offsetFromToday offset: Int,
        steps: Int,
        distance: Double? = nil,
        floors: Int = 0
    ) -> DayActivity {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .now)) ?? .now
        return DayActivity(
            date: date,
            steps: steps,
            distanceMeters: distance ?? Double(steps) * 0.76,
            floorsAscended: floors,
            averageActivePaceSecondsPerMeter: 0.01
        )
    }
}
