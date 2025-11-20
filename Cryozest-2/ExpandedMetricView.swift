//
//  ExpandedMetricView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

enum MetricType: String, CaseIterable {
    case hrv = "HRV"
    case rhr = "RHR"
    case spo2 = "SpO2"
    case respiratoryRate = "Respiratory Rate"
    case calories = "Calories"
    case steps = "Steps"
    case vo2Max = "VO2 Max"
    case deepSleep = "Deep Sleep"
    case remSleep = "REM Sleep"
    case coreSleep = "Core Sleep"
    case exertion = "Exertion"
    case recovery = "Recovery"
    case sleep = "Sleep"

    var icon: String {
        switch self {
        case .hrv: return "waveform.path.ecg"
        case .rhr: return "arrow.down.heart"
        case .spo2: return "drop"
        case .respiratoryRate: return "lungs"
        case .calories: return "flame"
        case .steps: return "figure.walk"
        case .vo2Max: return "lungs"
        case .deepSleep: return "bed.double.fill"
        case .remSleep: return "moon.stars.fill"
        case .coreSleep: return "moon.fill"
        case .exertion: return "flame.fill"
        case .recovery: return "heart.fill"
        case .sleep: return "moon.zzz.fill"
        }
    }

    var color: Color {
        switch self {
        case .hrv: return .cyan
        case .rhr: return .red
        case .spo2: return .blue
        case .respiratoryRate: return .purple
        case .calories: return .orange
        case .steps: return .green
        case .vo2Max: return .pink
        case .deepSleep: return .indigo
        case .remSleep: return .purple
        case .coreSleep: return .blue
        case .exertion: return .orange
        case .recovery: return .cyan
        case .sleep: return .indigo
        }
    }
}

struct ExpandedMetricView: View {
    let metricType: MetricType
    let model: RecoveryGraphModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }

            // Expanded content card
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: metricType.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [metricType.color.opacity(0.8), metricType.color.opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )

                        Text(metricType.rawValue)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                // Detail content (scrollable)
                ScrollView {
                    VStack(spacing: 20) {
                        detailView
                    }
                    .padding(20)
                }
            }
            .frame(maxWidth: 500)
            .frame(maxHeight: 600)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.1, green: 0.2, blue: 0.35),
                                Color(red: 0.15, green: 0.25, blue: 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: metricType.color.opacity(0.3), radius: 30, x: 0, y: 10)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch metricType {
        case .hrv:
            HRVDetailView(model: model)
        case .rhr:
            RHRDetailView(model: model)
        case .spo2:
            SpO2DetailView(model: model)
        case .respiratoryRate:
            RespiratoryRateDetailView(model: model)
        case .calories:
            CaloriesDetailView(model: model)
        case .steps:
            StepsDetailView(model: model)
        case .vo2Max:
            VO2MaxDetailView(model: model)
        case .deepSleep, .remSleep, .coreSleep:
            SleepMetricDetailView(metricType: metricType, model: model)
        case .exertion:
            // Exertion has its own dedicated widget with expanded state
            EmptyView()
        case .recovery:
            RecoveryDetailView(model: model)
        case .sleep:
            SleepDetailView(model: model)
        }
    }
}

struct SleepMetricDetailView: View {
    let metricType: MetricType
    let model: RecoveryGraphModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep stage data")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Text("Tap on the Sleep hero card or visit the Sleep tab for detailed sleep analysis and trends.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecoveryDetailView: View {
    let model: RecoveryGraphModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recovery Score Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Text("Your recovery score is calculated based on HRV, resting heart rate, sleep quality, and other metrics to help you understand how ready you are for activity.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SleepDetailView: View {
    let model: RecoveryGraphModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Score Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Text("Your sleep score is based on total sleep duration, sleep stages, and sleep consistency. Visit the Sleep tab for more detailed analysis.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
