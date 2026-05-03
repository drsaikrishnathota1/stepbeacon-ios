import SwiftUI

@main
struct StepBeaconApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var activityStore = ActivityStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settings)
                .environmentObject(activityStore)
        }
    }
}
