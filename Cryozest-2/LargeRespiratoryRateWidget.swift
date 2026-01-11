//
//  LargeRespiratoryRateWidget.swift
//  Cryozest-2
//
//  Full-width Respiratory Rate widget with inline expansion
//

import SwiftUI

struct LargeRespiratoryRateWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID

    private var respRate: Double {
        model.mostRecentRespiratoryRate ?? 0
    }

    private var status: RespRateStatus {
        let rate = Int(respRate)
        if rate < 12 { return .low }
        else if rate <= 20 { return .normal }
        else { return .high }
    }

    private var statusColor: Color {
        switch status {
        case .normal: return .green
        case .low, .high: return .orange
        }
    }

    private var isExpanded: Bool {
        expandedMetric == .respiratoryRate
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
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "lungs.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.purple)
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
            Text("Resp Rate")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(String(format: "%.0f", respRate))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("BrPM")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Subtitle
            Text("breaths/min")
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
                expandedMetric = .respiratoryRate
            }
        }
    }

    // MARK: - Expanded View
    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "lungs.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.purple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Respiratory Rate")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", respRate))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("BrPM")
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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Breathing visualization
                    breathingVisualization

                    // Status card
                    statusCard

                    // Range indicator
                    rangeIndicator

                    // Info card
                    infoCard
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

    private var breathingVisualization: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 100, height: 100)

            Image(systemName: "lungs.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.purple)
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
            Text("Normal Range")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 24)

                    // Colored zones
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.orange.opacity(0.4))
                            .frame(width: geometry.size.width * 0.3)

                        Rectangle()
                            .fill(Color.green.opacity(0.4))
                            .frame(width: geometry.size.width * 0.4)

                        Rectangle()
                            .fill(Color.orange.opacity(0.4))
                    }
                    .frame(height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                    // Current position
                    let normalizedRate = min(max((respRate - 8) / 20, 0), 1)
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                        .offset(x: CGFloat(normalizedRate) * geometry.size.width - 8)
                }
            }
            .frame(height: 24)

            HStack {
                Text("8")
                Spacer()
                Text("12")
                Spacer()
                Text("20")
                Spacer()
                Text("28")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white.opacity(0.4))
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
                    .foregroundColor(.purple)

                Text("About Respiratory Rate")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Your respiratory rate is the number of breaths you take per minute. A normal resting rate for adults is 12-20 breaths per minute. Changes can indicate stress, illness, or fitness level.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.08))
        )
    }
}

enum RespRateStatus {
    case low, normal, high

    var label: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }

    var description: String {
        switch self {
        case .low: return "Below typical resting range"
        case .normal: return "Within healthy resting range"
        case .high: return "Above typical resting range"
        }
    }
}
