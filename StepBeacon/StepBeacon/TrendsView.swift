import Charts
import SwiftUI

struct TrendsView: View {
    @EnvironmentObject private var activityStore: ActivityStore
    @EnvironmentObject private var settings: SettingsStore
    @State private var selectedRange: TrendRange = .month

    private var activities: [DayActivity] {
        activityStore.activities(for: selectedRange)
    }

    private var summary: InsightSummary {
        StepInsights.summary(for: activities, goal: settings.dailyStepGoal)
    }

    private var weekdayAverages: [WeekdayAverage] {
        StepInsights.weekdayAverages(from: activities)
    }

    private var maxWeekdayAverage: Int {
        max(weekdayAverages.map(\.averageSteps).max() ?? 1, 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Range", selection: $selectedRange) {
                    ForEach(TrendRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                chartCard
                summaryCard
                weekdayCard
                recentActivityCard
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Trends")
        .task {
            await activityStore.bootstrap(using: settings)
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(selectedRange.title) activity")
                .font(.title3.weight(.semibold))

            Chart(activities) { day in
                LineMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Steps", day.steps)
                )
                .foregroundStyle(StepTheme.accent.gradient)
                .lineStyle(.init(lineWidth: 3, lineCap: .round))

                AreaMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Steps", day.steps)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [StepTheme.accent.opacity(0.28), StepTheme.accent.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 220)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: selectedRange == .week ? 7 : 6)) { value in
                    AxisValueLabel(format: selectedRange == .week ? .dateTime.weekday(.narrow) : .dateTime.month(.abbreviated).day())
                }
            }
        }
        .padding(18)
        .background(StepTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(StepTheme.cardStroke))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Snapshot")
                .font(.title3.weight(.semibold))

            TrendMetricRow(title: "Average steps", value: summary.averageSteps.formatted())
            TrendMetricRow(title: "Goal hits", value: "\(summary.goalHitCount)")
            TrendMetricRow(title: "Total distance", value: formattedDistance(summary.totalDistanceMeters))
            TrendMetricRow(title: "Floors climbed", value: summary.totalFloors.formatted())
        }
        .padding(18)
        .background(StepTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(StepTheme.cardStroke))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var weekdayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weekday rhythm")
                .font(.title3.weight(.semibold))

            ForEach(weekdayAverages) { weekday in
                HStack(spacing: 12) {
                    Text(weekday.label)
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 24, alignment: .leading)

                    GeometryReader { geometry in
                        let ratio = max(Double(weekday.averageSteps) / Double(maxWeekdayAverage), 0.08)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(StepTheme.accentSecondary.gradient)
                            .frame(width: geometry.size.width * ratio)
                    }
                    .frame(height: 10)

                    Text(weekday.averageSteps.formatted())
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .background(StepTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(StepTheme.cardStroke))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent days")
                .font(.title3.weight(.semibold))

            ForEach(activities.suffix(7).reversed()) { day in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(day.date.formatted(.dateTime.weekday(.wide)))
                            .font(.subheadline.weight(.semibold))
                        Text(day.date.monthDayLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(day.steps.formatted())
                            .font(.headline.monospacedDigit())
                        Text(formattedDistance(day.distanceMeters))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .background(StepTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(StepTheme.cardStroke))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func formattedDistance(_ meters: Double) -> String {
        let converted = settings.distanceUnit.convert(distanceMeters: meters)
        return "\(converted.formatted(.number.precision(converted >= 10 ? .fractionLength(0) : .fractionLength(1)))) \(settings.distanceUnit.symbol)"
    }
}

private struct TrendMetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline.monospacedDigit())
        }
    }
}
