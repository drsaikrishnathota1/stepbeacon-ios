import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var dailyStepGoal: Int {
        didSet { UserDefaults.standard.set(dailyStepGoal, forKey: Keys.dailyStepGoal) }
    }

    @Published var distanceUnit: DistanceUnitPreference {
        didSet { UserDefaults.standard.set(distanceUnit.rawValue, forKey: Keys.distanceUnit) }
    }

    @Published var showFloors: Bool {
        didSet { UserDefaults.standard.set(showFloors, forKey: Keys.showFloors) }
    }

    @Published var prefersDemoData: Bool {
        didSet { UserDefaults.standard.set(prefersDemoData, forKey: Keys.prefersDemoData) }
    }

    private enum Keys {
        static let dailyStepGoal = "stepbeacon.dailyStepGoal"
        static let distanceUnit = "stepbeacon.distanceUnit"
        static let showFloors = "stepbeacon.showFloors"
        static let prefersDemoData = "stepbeacon.prefersDemoData"
    }

    init() {
        let defaults = UserDefaults.standard
        dailyStepGoal = defaults.object(forKey: Keys.dailyStepGoal) as? Int ?? 10_000
        distanceUnit = DistanceUnitPreference(
            rawValue: defaults.string(forKey: Keys.distanceUnit) ?? DistanceUnitPreference.automatic.rawValue
        ) ?? .automatic
        showFloors = defaults.object(forKey: Keys.showFloors) as? Bool ?? true
        prefersDemoData = defaults.object(forKey: Keys.prefersDemoData) as? Bool
            ?? (AppLaunchConfiguration.shouldAlwaysUseDemoData || AppLaunchConfiguration.hasForcedDemoArgument)
    }
}
