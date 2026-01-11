//
//  LargeVO2MaxWidget.swift
//  Cryozest-2
//
//  Full-width VO2 Max widget with inline expansion
//

import SwiftUI

struct LargeVO2MaxWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID

    private var vo2Max: Double {
        model.mostRecentVO2Max ?? 0
    }

    private var fitnessCategory: VO2Category {
        switch vo2Max {
        case 0..<35: return .poor
        case 35..<43: return .fair
        case 43..<53: return .good
        default: return .excellent
        }
    }

    private var categoryColor: Color {
        switch fitnessCategory {
        case .poor: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .excellent: return .green
        }
    }

    private var isExpanded: Bool {
        expandedMetric == .vo2Max
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
            // Top row: Icon and category
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 36, height: 36)

                    VStack(spacing: 0) {
                        Text("O₂")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.pink)
                    }
                }

                Spacer()

                // Category badge
                HStack(spacing: 3) {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 5, height: 5)

                    Text(fitnessCategory.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(categoryColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(categoryColor.opacity(0.15))
                )
            }

            // Title
            Text("VO2 Max")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(String(format: "%.1f", vo2Max))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("ml/kg")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Subtitle
            Text("cardio fitness")
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
                expandedMetric = .vo2Max
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
                            .fill(Color.pink.opacity(0.2))
                            .frame(width: 40, height: 40)

                        VStack(spacing: 0) {
                            Text("O₂")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.pink)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("VO2 Max")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", vo2Max))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("ml/kg/min")
                                .font(.system(size: 12, weight: .medium))
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
                    // Gauge visualization
                    gaugeVisualization

                    // Category card
                    categoryCard

                    // Reference ranges
                    referenceRanges

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

    private var gaugeVisualization: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(90))

                // Colored arc segments
                Circle()
                    .trim(from: 0.15, to: 0.325)
                    .stroke(Color.red.opacity(0.6), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(90))

                Circle()
                    .trim(from: 0.325, to: 0.5)
                    .stroke(Color.orange.opacity(0.6), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(90))

                Circle()
                    .trim(from: 0.5, to: 0.675)
                    .stroke(Color.yellow.opacity(0.6), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(90))

                Circle()
                    .trim(from: 0.675, to: 0.85)
                    .stroke(Color.green.opacity(0.6), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(90))

                // Needle indicator
                let normalizedValue = min(max((vo2Max - 20) / 45, 0), 1)
                let angle = -135 + (normalizedValue * 270)

                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4, height: 50)
                    .offset(y: -25)
                    .rotationEffect(.degrees(angle))
                    .shadow(color: .black.opacity(0.3), radius: 2)

                // Center circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.2), radius: 2)

                // Value display
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", vo2Max))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .offset(y: 50)
            }
            .frame(height: 180)

            // Range labels
            HStack {
                Text("20")
                Spacer()
                Text("35")
                Spacer()
                Text("43")
                Spacer()
                Text("53")
                Spacer()
                Text("65+")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white.opacity(0.4))
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
    }

    private var categoryCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(categoryColor)
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(fitnessCategory.label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(fitnessCategory.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(categoryColor.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(categoryColor.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private var referenceRanges: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reference Ranges")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 6) {
                rangeRow(label: "Poor", range: "< 35", color: .red, isActive: fitnessCategory == .poor)
                rangeRow(label: "Fair", range: "35 - 42", color: .orange, isActive: fitnessCategory == .fair)
                rangeRow(label: "Good", range: "43 - 52", color: .yellow, isActive: fitnessCategory == .good)
                rangeRow(label: "Excellent", range: "53+", color: .green, isActive: fitnessCategory == .excellent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func rangeRow(label: String, range: String, color: Color, isActive: Bool) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 13, weight: isActive ? .bold : .medium))
                .foregroundColor(isActive ? .white : .white.opacity(0.7))

            Spacer()

            Text(range)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? color.opacity(0.15) : Color.clear)
        )
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pink)

                Text("About VO2 Max")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("VO2 Max measures the maximum amount of oxygen your body can use during intense exercise. It's one of the best indicators of cardiovascular fitness and endurance capacity.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pink.opacity(0.08))
        )
    }
}

enum VO2Category {
    case poor, fair, good, excellent

    var label: String {
        switch self {
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }

    var description: String {
        switch self {
        case .poor: return "Below average cardiovascular fitness"
        case .fair: return "Average cardiovascular fitness"
        case .good: return "Above average cardiovascular fitness"
        case .excellent: return "Superior cardiovascular fitness"
        }
    }
}
