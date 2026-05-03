import SwiftUI

struct RootTabView: View {
    @State private var selection = AppLaunchConfiguration.initialTab

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                DashboardView()
            }
            .tag(AppTab.today)
            .tabItem {
                Label("Today", systemImage: "figure.walk.circle.fill")
            }

            NavigationStack {
                TrendsView()
            }
            .tag(AppTab.trends)
            .tabItem {
                Label("Trends", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                SettingsView()
            }
            .tag(AppTab.settings)
            .tabItem {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
        }
        .tint(StepTheme.accent)
    }
}
