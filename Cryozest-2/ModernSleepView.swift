//
//  ModernSleepView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

struct ModernSleepView: View {
    @ObservedObject var dailySleepModel: DailySleepViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var sleepStartTime: String = "N/A"
    @State private var sleepEndTime: String = "N/A"

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.25),
                    Color(red: 0.08, green: 0.12, blue: 0.22)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                    // Hero section with large score ring
                    VStack(spacing: 16) {
                        ZStack {
                            // Large circular progress ring
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 16)
                                .frame(width: 200, height: 200)

                            Circle()
                                .trim(from: 0, to: CGFloat(dailySleepModel.sleepScore / 100))
                                .stroke(
                                    LinearGradient(
                                        colors: [.purple, .blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                )
                                .frame(width: 200, height: 200)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: dailySleepModel.sleepScore)

                            // Score in center
                            VStack(spacing: 4) {
                                Text("\(Int(dailySleepModel.sleepScore))")
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Sleep Score")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.bottom, 8)

                        // Time range
                        if sleepStartTime != "N/A" && sleepEndTime != "N/A" {
                            HStack(spacing: 8) {
                                Image(systemName: "bed.double.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.purple.opacity(0.8))

                                Text("\(sleepStartTime) - \(sleepEndTime)")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                            )
                        }

                        // Total duration
                        if dailySleepModel.totalTimeAsleep != "N/A" {
                            Text(dailySleepModel.totalTimeAsleep)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.vertical, 20)

                    // Sleep stages breakdown
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Sleep Stages")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            SleepStageRow(
                                icon: "moon.zzz.fill",
                                title: "Deep",
                                value: dailySleepModel.totalDeepSleep,
                                color: .indigo
                            )

                            SleepStageRow(
                                icon: "moon.stars.fill",
                                title: "REM",
                                value: dailySleepModel.totalRemSleep,
                                color: .purple
                            )

                            SleepStageRow(
                                icon: "moon.fill",
                                title: "Core",
                                value: dailySleepModel.totalCoreSleep,
                                color: .blue
                            )

                            SleepStageRow(
                                icon: "eye.fill",
                                title: "Awake",
                                value: dailySleepModel.totalTimeAwake,
                                color: .orange
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 20)

                    // Restorative sleep insight
                    if dailySleepModel.restorativeSleepPercentage > 0 {
                        ModernInsightCard(
                            icon: "sparkles",
                            title: "Restorative Sleep",
                            value: "\(Int(dailySleepModel.restorativeSleepPercentage))%",
                            description: "Deep + REM sleep helps your body repair and mind refresh",
                            accentColor: .cyan
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }

                    // Heart rate insight
                    if dailySleepModel.heartRateDifferencePercentage > 0 {
                        ModernInsightCard(
                            icon: "heart.fill",
                            title: "Heart Rate Recovery",
                            value: "\(Int(dailySleepModel.heartRateDifferencePercentage))%",
                            description: "Your heart rate dropped during sleep, indicating good recovery",
                            accentColor: .red
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            fetchSleepTimes()
        }
    }

    private func fetchSleepTimes() {
        getSleepTimesYesterday { (start, end) in
            if let start = start, let end = end {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "h:mm a"

                self.sleepStartTime = dateFormatter.string(from: start)
                self.sleepEndTime = dateFormatter.string(from: end)
            } else {
                self.sleepStartTime = "N/A"
                self.sleepEndTime = "N/A"
            }
        }
    }
}

struct SleepStageRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }

            // Title
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            // Value
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ModernInsightCard: View {
    let icon: String
    let title: String
    let value: String
    let description: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accentColor)

                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
            }

            Text(description)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [accentColor.opacity(0.3), accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: accentColor.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}
