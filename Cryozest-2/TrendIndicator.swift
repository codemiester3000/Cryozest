//
//  TrendIndicator.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Trend arrows and percentage changes
//

import SwiftUI

enum TrendDirection {
    case up, down, neutral

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .white.opacity(0.6)
        }
    }

    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .neutral: return "minus"
        }
    }
}

struct TrendIndicator: View {
    let currentValue: Double
    let previousValue: Double
    let format: TrendFormat

    enum TrendFormat {
        case percentage
        case absolute
        case time
    }

    private var trend: TrendDirection {
        if currentValue > previousValue {
            return .up
        } else if currentValue < previousValue {
            return .down
        } else {
            return .neutral
        }
    }

    private var changePercentage: Double {
        guard previousValue != 0 else { return 0 }
        return ((currentValue - previousValue) / previousValue) * 100
    }

    private var absoluteChange: Double {
        return currentValue - previousValue
    }

    private var displayText: String {
        switch format {
        case .percentage:
            return String(format: "%.0f%%", abs(changePercentage))
        case .absolute:
            return String(format: "%.0f", abs(absoluteChange))
        case .time:
            let hours = Int(abs(absoluteChange)) / 3600
            let minutes = (Int(abs(absoluteChange)) % 3600) / 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(trend.color)

            Text(displayText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(trend.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(trend.color.opacity(0.15))
        )
    }
}

// Helper view for adding trend to existing metrics
struct MetricWithTrend: View {
    let title: String
    let value: String
    let currentValue: Double
    let previousValue: Double
    let trendFormat: TrendIndicator.TrendFormat
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                TrendIndicator(
                    currentValue: currentValue,
                    previousValue: previousValue,
                    format: trendFormat
                )
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
