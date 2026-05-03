import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var activityStore: ActivityStore
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section("Daily Goal") {
                Stepper(value: $settings.dailyStepGoal, in: 4_000...30_000, step: 500) {
                    HStack {
                        Text("Goal")
                        Spacer()
                        Text("\(settings.dailyStepGoal.formatted()) steps")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Display") {
                Picker("Distance Unit", selection: $settings.distanceUnit) {
                    ForEach(DistanceUnitPreference.allCases) { unit in
                        Text(unit.title).tag(unit)
                    }
                }

                Toggle("Show floors climbed", isOn: $settings.showFloors)
            }

            Section("Data Source") {
                Toggle("Use demo activity", isOn: $settings.prefersDemoData)
                LabeledContent("Current source", value: activityStore.dataSource.label)
                LabeledContent("Motion access", value: activityStore.authorizationState.title)

                Button("Refresh Step Timeline") {
                    Task { await activityStore.refresh(using: settings) }
                }

                if activityStore.authorizationState == .denied {
                    Button("Open iPhone Settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        openURL(url)
                    }
                }
            }

            Section("About StepBeacon") {
                Text("StepBeacon is an original step-tracker built around goal progress, weekly trends, streaks, and quick-glance momentum insights.")
                Text("Simulator runs use demo activity so the full app can be tested without a physical iPhone on your desk.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .task {
            await activityStore.bootstrap(using: settings)
        }
        .onChange(of: settings.prefersDemoData) { _, _ in
            Task { await activityStore.refresh(using: settings) }
        }
    }
}
