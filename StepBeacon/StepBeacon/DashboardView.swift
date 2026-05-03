import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var activityStore: ActivityStore
    @EnvironmentObject private var settings: SettingsStore

    private var today: DayActivity { activityStore.today }
    private var summary: InsightSummary {
        StepInsights.summary(for: activityStore.days, goal: settings.dailyStepGoal)
    }
    private var achievements: [AchievementStatus] {
        AchievementEngine.statuses(for: activityStore.days, goal: settings.dailyStepGoal)
            .filter(\.isUnlocked)
            .sorted { ($0.unlockedDate ?? .distantPast) > ($1.unlockedDate ?? .distantPast) }
    }
    private var recentWeek: [DayActivity] {
        Array(activityStore.activities(for: .week))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard

                if activityStore.authorizationState != .authorized && activityStore.dataSource != .demo {
                    motionStatusCard
                }

                weekSnapshotCard
                achievementsCard
                highlightsCard
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Today")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: activityStore.shareText(goal: settings.dailyStepGoal, distanceUnit: settings.distanceUnit)) {
                    Image(systemName: "square.and.arrow.up")
                }

                Button {
                    Task { await activityStore.refresh(using: settings) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await activityStore.bootstrap(using: settings)
        }
        .refreshable {
            await activityStore.refresh(using: settings)
        }
        .onChange(of: settings.prefersDemoData) { _, _ in
            Task { await activityStore.refresh(using: settings) }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Step goal")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))

                    Text(today.steps.formatted())
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("of \(settings.dailyStepGoal.formatted()) steps")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.88))
                }

                Spacer(minLength: 12)

                ProgressRing(progress: progressFraction, lineWidth: 12)
                    .frame(width: 88, height: 88)
                    .overlay {
                        Text("\(Int(progressFraction * 100))%")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.white)
                    }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    title: "Distance",
                    value: formattedDistance(today.distanceMeters),
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                    tint: StepTheme.accentSecondary
                )

                MetricCard(
                    title: "Streak",
                    value: "\(summary.currentStreak) days",
                    systemImage: "flame.fill",
                    tint: StepTheme.accentRose
                )

                if settings.showFloors {
                    MetricCard(
                        title: "Floors",
                        value: today.floorsAscended.formatted(),
                        systemImage: "stairs",
                        tint: StepTheme.accentWarm
                    )
                }

                MetricCard(
                    title: "Avg pace",
                    value: formattedPace(today.averageActivePaceSecondsPerMeter),
                    systemImage: "gauge.with.dots.needle.50percent",
                    tint: StepTheme.accent
                )
            }

            HStack {
                Label(activityStore.dataSource.label, systemImage: activityStore.dataSource == .live ? "sensor.fill" : "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                if let lastSyncDate = activityStore.lastSyncDate {
                    Text("Updated \(lastSyncDate.formatted(.dateTime.hour().minute()))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .padding(22)
        .background(StepTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var motionStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(activityStore.authorizationState.title, systemImage: "hand.raised.app")
                .font(.headline)
            Text(activityStore.authorizationState.guidance)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                if activityStore.authorizationState.canRequestAccess {
                    Button("Allow Motion Access") {
                        Task { await activityStore.requestAccess(using: settings) }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if activityStore.authorizationState == .denied {
                    OpenSettingsButton()
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StepTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(StepTheme.cardStroke))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var weekSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Last 7 Days")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(summary.weeklyTrendDelta >= 0 ? "+\(summary.weeklyTrendDelta.formatted()) avg" : "\(summary.weeklyTrendDelta.formatted()) avg")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(summary.weeklyTrendDelta >= 0 ? StepTheme.accent : .secondary)
            }

            Chart(recentWeek) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Steps", day.steps)
                )
                .foregroundStyle(day.date == today.date ? StepTheme.accent.gradient : StepTheme.accentSecondary.gradient)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)

            Text("You hit your goal on \(summary.goalHitCount) of the last \(activityStore.days.count) tracked days.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(StepTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(StepTheme.cardStroke))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Momentum")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("\(achievements.count) unlocked")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if achievements.isEmpty {
                Text("Your first badge will show up as soon as you start building step history.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(achievements.prefix(6)) { achievement in
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: achievement.definition.systemImage)
                                    .font(.title2)
                                    .foregroundStyle(StepTheme.tint(for: achievement.definition.kind))
                                Text(achievement.definition.title)
                                    .font(.headline)
                                Text(achievement.definition.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .frame(width: 168, alignment: .leading)
                            .padding(16)
                            .background(StepTheme.cardSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(StepTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(StepTheme.cardStroke))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Highlights")
                .font(.title3.weight(.semibold))

            highlightRow(
                title: "Best day",
                value: summary.bestDay?.steps.formatted() ?? "0",
                footnote: summary.bestDay?.date.monthDayLabel ?? "No activity yet"
            )

            highlightRow(
                title: "Average day",
                value: summary.averageSteps.formatted(),
                footnote: "across the last \(activityStore.days.count) tracked days"
            )

            highlightRow(
                title: "Distance total",
                value: formattedDistance(summary.totalDistanceMeters),
                footnote: "all activity in this snapshot"
            )
        }
        .padding(18)
        .background(StepTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(StepTheme.cardStroke))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func highlightRow(title: String, value: String, footnote: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
        }
    }

    private var progressFraction: Double {
        min(Double(today.steps) / Double(max(settings.dailyStepGoal, 1)), 1)
    }

    private func formattedDistance(_ meters: Double) -> String {
        let converted = settings.distanceUnit.convert(distanceMeters: meters)
        let value: String
        if converted >= 10 {
            value = converted.formatted(.number.precision(.fractionLength(0)))
        } else {
            value = converted.formatted(.number.precision(.fractionLength(1)))
        }
        return "\(value) \(settings.distanceUnit.symbol)"
    }

    private func formattedPace(_ secondsPerMeter: Double?) -> String {
        guard let secondsPerMeter, secondsPerMeter > 0 else { return "Calibrating" }
        let minutesPerKilometer = (secondsPerMeter * 1_000) / 60
        return "\(minutesPerKilometer.formatted(.number.precision(.fractionLength(1)))) min/km"
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.78))
                Text(value)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.white, Color.white.opacity(0.8), StepTheme.accentWarm],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

private struct OpenSettingsButton: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button("Open Settings") {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(url)
        }
        .buttonStyle(.bordered)
    }
}
