//
//  CaloriesDetailView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

struct CaloriesDetailView: View {
    @ObservedObject var model: RecoveryGraphModel

    private var totalCalories: Int {
        Int((model.mostRecentActiveCalories ?? 0) + (model.mostRecentRestingCalories ?? 0))
    }

    private var activeCalories: Int {
        Int(model.mostRecentActiveCalories ?? 0)
    }

    private var restingCalories: Int {
        Int(model.mostRecentRestingCalories ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Current value
            VStack(spacing: 8) {
                Text("Total Calories Burned")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(totalCalories)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.orange)

                    Text("kcal")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )

            // Breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Breakdown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    breakdownCard(
                        title: "Active",
                        value: activeCalories,
                        color: .orange,
                        percentage: totalCalories > 0 ? Double(activeCalories) / Double(totalCalories) : 0
                    )

                    breakdownCard(
                        title: "Resting",
                        value: restingCalories,
                        color: .cyan,
                        percentage: totalCalories > 0 ? Double(restingCalories) / Double(totalCalories) : 0
                    )
                }
            }

            // Info card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)

                    Text("About Calories")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Active calories are burned through movement and exercise. Resting calories are burned by your body's basic functions throughout the day.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    private func breakdownCard(title: String, value: Int, color: Color, percentage: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Text("\(value)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text("\(Int(percentage * 100))% of total")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
