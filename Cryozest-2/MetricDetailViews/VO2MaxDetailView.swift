//
//  VO2MaxDetailView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

struct VO2MaxDetailView: View {
    @ObservedObject var model: RecoveryGraphModel

    private var vo2Max: Double {
        model.mostRecentVO2Max ?? 0.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Current value
            VStack(spacing: 8) {
                Text("VO2 Max")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", vo2Max))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.pink)

                    Text("ml/kg/min")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pink.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                    )
            )

            // Fitness category
            let category = getFitnessCategory(vo2Max: vo2Max)
            VStack(alignment: .leading, spacing: 12) {
                Text("Fitness Category")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Circle()
                        .fill(category.color)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.label)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Text(category.description)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(category.color.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(category.color.opacity(0.3), lineWidth: 1)
                        )
                )
            }

            // Range indicators
            VStack(alignment: .leading, spacing: 12) {
                Text("Reference Ranges")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                VStack(spacing: 8) {
                    rangeRow(label: "Poor", range: "< 35", color: .red)
                    rangeRow(label: "Fair", range: "35 - 42", color: .orange)
                    rangeRow(label: "Good", range: "43 - 52", color: .yellow)
                    rangeRow(label: "Excellent", range: "53+", color: .green)
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

            // Info card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pink)

                    Text("About VO2 Max")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("VO2 Max is the maximum amount of oxygen your body can use during intense exercise. Higher values indicate better cardiovascular fitness and endurance.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pink.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    private func rangeRow(label: String, range: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Text(range)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }

    private func getFitnessCategory(vo2Max: Double) -> (label: String, description: String, color: Color) {
        switch vo2Max {
        case 0..<35:
            return ("Poor", "Below average fitness level", .red)
        case 35..<43:
            return ("Fair", "Below average fitness level", .orange)
        case 43..<53:
            return ("Good", "Above average fitness level", .yellow)
        default:
            return ("Excellent", "Superior cardiovascular fitness", .green)
        }
    }
}
