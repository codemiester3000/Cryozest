//
//  SessionFrequencyChart.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Bar chart showing session frequency by day of week
//

import SwiftUI
import CoreData

struct SessionFrequencyChart: View {
    let sessions: [TherapySessionEntity]
    let therapyType: TherapyType

    private var frequencyData: [Int] {
        let calendar = Calendar.current
        var dayCounts = Array(repeating: 0, count: 7)

        sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
            .forEach { date in
                let weekday = calendar.component(.weekday, from: date)
                dayCounts[weekday - 1] += 1
            }

        return dayCounts
    }

    private var maxCount: Int {
        frequencyData.max() ?? 1
    }

    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(therapyType.color)

                Text("Session Frequency")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            // Background bar
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 120)

                            // Value bar
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            therapyType.color.opacity(0.8),
                                            therapyType.color.opacity(0.5)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: barHeight(for: frequencyData[index]))

                            // Count label
                            if frequencyData[index] > 0 {
                                Text("\(frequencyData[index])")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.bottom, 8)
                            }
                        }

                        Text(dayLabels[index])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func barHeight(for count: Int) -> CGFloat {
        guard maxCount > 0 else { return 0 }
        let ratio = CGFloat(count) / CGFloat(maxCount)
        return max(ratio * 120, count > 0 ? 20 : 0)
    }
}
