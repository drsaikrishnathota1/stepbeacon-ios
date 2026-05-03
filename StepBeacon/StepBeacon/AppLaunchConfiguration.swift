import Foundation

enum AppLaunchConfiguration {
    private static let arguments = ProcessInfo.processInfo.arguments
    private static let environment = ProcessInfo.processInfo.environment

    static let isScreenshotMode = arguments.contains("APPSTORE_SCREENSHOTS")
    static let hasForcedDemoArgument = arguments.contains("STEPBEACON_DEMO")
        || environment["STEPBEACON_DEMO"] == "1"

    static var shouldAlwaysUseDemoData: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        isScreenshotMode
        #endif
    }

    static var initialTab: AppTab {
        guard
            let rawValue = environment["STEPBEACON_TAB"],
            let tab = AppTab(rawValue: rawValue)
        else {
            return .today
        }

        return tab
    }

    static var seededActivities: [DayActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let seededSteps = [
            5_940, 7_220, 8_410, 6_120, 9_880, 10_420, 12_180,
            6_880, 8_030, 9_740, 7_460, 10_210, 11_050, 12_600,
            7_100, 8_650, 9_320, 10_480, 11_340, 9_910, 13_280,
            8_740, 9_560, 12_040, 10_860, 11_720, 13_110, 14_080
        ]
        let seededFloors = [
            7, 9, 10, 8, 12, 13, 16,
            8, 10, 11, 8, 13, 14, 17,
            9, 10, 11, 13, 15, 12, 18,
            10, 11, 15, 14, 16, 18, 20
        ]

        return seededSteps.enumerated().compactMap { index, steps in
            guard let date = calendar.date(byAdding: .day, value: index - (seededSteps.count - 1), to: today) else {
                return nil
            }

            return DayActivity(
                date: date,
                steps: steps,
                distanceMeters: Double(steps) * 0.76,
                floorsAscended: seededFloors[index],
                averageActivePaceSecondsPerMeter: 0.40 + (Double(index % 5) * 0.02)
            )
        }
    }
}
