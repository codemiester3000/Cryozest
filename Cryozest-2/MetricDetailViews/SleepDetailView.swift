//
//  SleepDetailView.swift
//  Cryozest-2
//

import SwiftUI

struct SleepDetailView: View {
    @ObservedObject var recoveryModel: RecoveryGraphModel
    @ObservedObject var sleepModel: DailySleepViewModel

    @State private var last7DaysSleep: [(Date, Double)] = []
    @State private var isLoading = true

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    private var sleepHours: Double? {
        if let str = recoveryModel.previousNightSleepDuration {
            return Double(str)
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Current value card
            VStack(spacing: 8) {
                Text("Last Night's Sleep")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let hours = sleepHours {
                        Text(String(format: "%.1f", hours))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.indigo)
                    } else {
                        Text("--")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                    }

                    Text("hrs")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Sleep score
                if let score = recoveryModel.sleepScorePercentage {
                    HStack(spacing: 6) {
                        Image(systemName: score >= 80 ? "star.fill" : score >= 60 ? "star.leadinghalf.filled" : "star")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(score >= 80 ? .green : score >= 60 ? .yellow : .orange)

                        Text("Sleep Score: \(score)%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.indigo.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.indigo.opacity(0.3), lineWidth: 1)
                    )
            )

            // Sleep stages
            if sleepModel.totalTimeAsleep != "N/A" {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sleep Stages")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    VStack(spacing: 10) {
                        SleepStageRow(label: "Deep Sleep", value: sleepModel.totalDeepSleep, color: .indigo)
                        SleepStageRow(label: "Core Sleep", value: sleepModel.totalCoreSleep, color: .blue)
                        SleepStageRow(label: "REM Sleep", value: sleepModel.totalRemSleep, color: .purple)
                        SleepStageRow(label: "Awake", value: sleepModel.totalTimeAwake, color: .orange)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }

            // Stats summary
            HStack(spacing: 12) {
                SleepStatCard(
                    icon: "bed.double.fill",
                    label: "Time in Bed",
                    value: sleepModel.totalTimeInBed,
                    color: .indigo
                )

                SleepStatCard(
                    icon: "moon.zzz.fill",
                    label: "Time Asleep",
                    value: sleepModel.totalTimeAsleep,
                    color: .purple
                )
            }

            if sleepModel.restorativeSleepPercentage > 0 {
                HStack(spacing: 12) {
                    SleepStatCard(
                        icon: "bolt.heart.fill",
                        label: "Restorative",
                        value: String(format: "%.0f%%", sleepModel.restorativeSleepPercentage),
                        color: .green
                    )

                    if sleepModel.averageHeartRateDuringSleep > 0 {
                        SleepStatCard(
                            icon: "heart.fill",
                            label: "Sleep HR",
                            value: String(format: "%.0f bpm", sleepModel.averageHeartRateDuringSleep),
                            color: .red
                        )
                    }
                }
            }

            // 7-day history
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .indigo))
                    Spacer()
                }
                .padding()
            } else if !last7DaysSleep.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last 7 Days")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    VStack(spacing: 8) {
                        ForEach(last7DaysSleep, id: \.0) { date, hours in
                            DaySleepRow(
                                date: date,
                                hours: hours,
                                dateFormatter: dayFormatter
                            )
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }

            // Info card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.indigo)

                    Text("About Sleep")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Adults need 7-9 hours of quality sleep. Deep and REM sleep are critical for recovery, memory consolidation, and immune function.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.indigo.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.indigo.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .onAppear { loadHistory() }
        .onChange(of: recoveryModel.selectedDate) { _ in loadHistory() }
    }

    private func loadHistory() {
        isLoading = true
        let calendar = Calendar.current
        let ref = recoveryModel.selectedDate
        var entries: [(Date, Double)] = []
        let group = DispatchGroup()

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: ref) else { continue }
            group.enter()
            HealthKitManager.shared.fetchSleepDurationForDay(date: day) { duration in
                if let duration = duration, duration > 0 {
                    let hours = duration / 3600.0
                    DispatchQueue.main.async {
                        entries.append((calendar.startOfDay(for: day), hours))
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.last7DaysSleep = entries.sorted { $0.0 > $1.0 }
            self.isLoading = false
        }
    }
}

struct SleepStageRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

struct SleepStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)

            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct DaySleepRow: View {
    let date: Date
    let hours: Double
    let dateFormatter: DateFormatter

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var sleepQuality: Color {
        if hours >= 7.5 { return .green }
        if hours >= 6.5 { return .yellow }
        return .orange
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(dateFormatter.string(from: date))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    if isToday {
                        Text("Today")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.cyan.opacity(0.15))
                            )
                    }
                }

                Text(String(format: "%.1f hrs", hours))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Quality indicator
            Circle()
                .fill(sleepQuality)
                .frame(width: 8, height: 8)

            // Mini progress bar (target 8 hrs)
            GeometryReader { _ in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(sleepQuality)
                        .frame(width: 60 * min(hours / 8.0, 1.0), height: 6)
                }
            }
            .frame(width: 60, height: 6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hours >= 7.5 ? Color.green.opacity(0.05) : Color.white.opacity(0.03))
        )
    }
}
