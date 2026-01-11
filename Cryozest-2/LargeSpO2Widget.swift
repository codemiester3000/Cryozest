//
//  LargeSpO2Widget.swift
//  Cryozest-2
//
//  Full-width Blood Oxygen widget with inline expansion
//

import SwiftUI

struct LargeSpO2Widget: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID

    private var spo2Decimal: Double {
        model.mostRecentSPO2 ?? 0
    }

    private var spo2Percentage: Int {
        Int(spo2Decimal * 100)
    }

    private var status: SpO2Status {
        if spo2Percentage >= 98 { return .excellent }
        else if spo2Percentage >= 95 { return .normal }
        else if spo2Percentage >= 90 { return .low }
        else { return .veryLow }
    }

    private var statusColor: Color {
        switch status {
        case .excellent: return .cyan
        case .normal: return .green
        case .low: return .orange
        case .veryLow: return .red
        }
    }

    private var isExpanded: Bool {
        expandedMetric == .spo2
    }

    var body: some View {
        Group {
            if isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
    }

    // MARK: - Collapsed View (Half-width compact)
    private var collapsedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: Icon and status
            HStack {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "drop.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(statusColor)
                }

                Spacer()

                // Status badge
                HStack(spacing: 3) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 5, height: 5)

                    Text(status.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.15))
                )
            }

            // Title
            Text("Blood Oxygen")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(spo2Percentage)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Subtitle
            Text("SpO₂")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                expandedMetric = .spo2
            }
        }
    }

    // MARK: - Expanded View
    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with close button
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "drop.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(statusColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Blood Oxygen")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(spo2Percentage)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("%")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        expandedMetric = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(16)

            // Expanded content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Large visualization
                    oxygenVisualization

                    // Status card
                    statusCard

                    // Range indicator
                    rangeIndicator

                    // Info card
                    infoCard

                    // Warning if needed
                    if spo2Percentage < 95 {
                        warningCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
    }

    private var oxygenVisualization: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 12)
                .frame(width: 140, height: 140)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(spo2Percentage) / 100.0)
                .stroke(
                    AngularGradient(
                        colors: [statusColor, statusColor.opacity(0.5)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 4) {
                Text("\(spo2Percentage)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("percent")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(statusColor)
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(status.label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(status.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(statusColor.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusColor.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private var rangeIndicator: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Oxygen Saturation Range")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            // Visual range bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 24)

                    // Colored zones
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.red.opacity(0.4))
                            .frame(width: geometry.size.width * 0.1)

                        Rectangle()
                            .fill(Color.orange.opacity(0.4))
                            .frame(width: geometry.size.width * 0.05)

                        Rectangle()
                            .fill(Color.green.opacity(0.4))
                            .frame(width: geometry.size.width * 0.03)

                        Rectangle()
                            .fill(Color.cyan.opacity(0.4))
                    }
                    .frame(height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                    // Current position marker
                    let position = min(max(CGFloat(spo2Percentage - 85) / 15.0, 0), 1) * geometry.size.width
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                        .offset(x: position - 8)
                }
            }
            .frame(height: 24)

            // Labels
            HStack {
                Text("85%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))

                Spacer()

                Text("90%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))

                Spacer()

                Text("95%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))

                Spacer()

                Text("100%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(statusColor)

                Text("About Blood Oxygen")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("SpO2 measures the percentage of oxygen-saturated hemoglobin in your blood. Values between 95-100% are considered normal for healthy individuals at sea level.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(statusColor.opacity(0.08))
        )
    }

    private var warningCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.orange)

            Text("Consider consulting a healthcare provider if readings remain below 95%")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - SpO2 Status
enum SpO2Status {
    case excellent, normal, low, veryLow

    var label: String {
        switch self {
        case .excellent: return "Excellent"
        case .normal: return "Normal"
        case .low: return "Low"
        case .veryLow: return "Very Low"
        }
    }

    var shortLabel: String {
        switch self {
        case .excellent: return "Optimal oxygen saturation"
        case .normal: return "Normal range"
        case .low: return "Below optimal"
        case .veryLow: return "Seek medical attention"
        }
    }

    var description: String {
        switch self {
        case .excellent: return "Your blood oxygen level is optimal"
        case .normal: return "Your blood oxygen is in the healthy range"
        case .low: return "Your oxygen level is below normal range"
        case .veryLow: return "Please consult a healthcare provider"
        }
    }
}
