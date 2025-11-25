//
//  MetricConfigurationView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/8/25.
//

import SwiftUI

struct MetricConfigurationView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var configManager = MetricConfigurationManager.shared

    var body: some View {
        ZStack {
            // Deep navy background
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    Text("Metrics")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Invisible placeholder for symmetry
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 20)

                Text("Customize your daily view")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 20) {
                        // Daily Widgets Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily Widgets")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)

                            Text("Additional cards on the Daily tab")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 4)

                            VStack(spacing: 12) {
                                ForEach(DailyWidget.allCases) { widget in
                                    WidgetToggleRow(
                                        widget: widget,
                                        isEnabled: configManager.isEnabled(widget)
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            configManager.toggle(widget)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)

                        // Hero Scores Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hero Scores")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)

                            Text("Main scores displayed at the top")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 4)

                            VStack(spacing: 12) {
                                ForEach(HeroScore.allCases) { heroScore in
                                    HeroScoreToggleRow(
                                        heroScore: heroScore,
                                        isEnabled: configManager.isEnabled(heroScore)
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            configManager.toggle(heroScore)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)

                        // Health Metrics Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Health Metrics")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)

                            Text("Detailed metrics in the grid")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 4)

                            VStack(spacing: 12) {
                                ForEach(HealthMetric.allCases) { metric in
                                    MetricToggleRow(
                                        metric: metric,
                                        isEnabled: configManager.isEnabled(metric)
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            configManager.toggle(metric)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct HeroScoreToggleRow: View {
    let heroScore: HeroScore
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: heroScore.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isEnabled ? heroScore.color : .white.opacity(0.4))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isEnabled ? heroScore.color.opacity(0.2) : Color.white.opacity(0.05))
                    )

                // Hero score name
                Text(heroScore.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.5))

                Spacer()

                // Toggle indicator
                ZStack {
                    Circle()
                        .strokeBorder(isEnabled ? heroScore.color : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isEnabled {
                        Circle()
                            .fill(heroScore.color)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.25))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isEnabled
                            ? Color.white.opacity(0.12)
                            : Color.white.opacity(0.06)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isEnabled ? heroScore.color.opacity(0.4) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MetricToggleRow: View {
    let metric: HealthMetric
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: metric.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isEnabled ? .cyan : .white.opacity(0.4))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isEnabled ? Color.cyan.opacity(0.2) : Color.white.opacity(0.05))
                    )

                // Metric name
                Text(metric.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.5))

                Spacer()

                // Toggle indicator
                ZStack {
                    Circle()
                        .strokeBorder(isEnabled ? Color.cyan : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isEnabled {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.25))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isEnabled
                            ? Color.white.opacity(0.12)
                            : Color.white.opacity(0.06)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isEnabled ? Color.cyan.opacity(0.4) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WidgetToggleRow: View {
    let widget: DailyWidget
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: widget.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isEnabled ? widget.color : .white.opacity(0.4))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isEnabled ? widget.color.opacity(0.2) : Color.white.opacity(0.05))
                    )

                // Widget name and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(widget.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isEnabled ? .white : .white.opacity(0.5))

                    Text(widget.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                // Toggle indicator
                ZStack {
                    Circle()
                        .strokeBorder(isEnabled ? widget.color : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isEnabled {
                        Circle()
                            .fill(widget.color)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.25))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isEnabled
                            ? Color.white.opacity(0.12)
                            : Color.white.opacity(0.06)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isEnabled ? widget.color.opacity(0.4) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MetricConfigurationView()
}
