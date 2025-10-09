//
//  RespiratoryRateDetailView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

struct RespiratoryRateDetailView: View {
    @ObservedObject var model: RecoveryGraphModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Current value
            VStack(spacing: 8) {
                Text("Respiratory Rate")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", model.mostRecentRespiratoryRate ?? 0.0))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)

                    Text("BrPM")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
            )

            // Status
            let rate = Int(model.mostRecentRespiratoryRate ?? 0)
            let status = getRespiratoryStatus(rate: rate)
            VStack(alignment: .leading, spacing: 12) {
                Text("Status")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(status.label)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)

                        Text(status.description)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(status.color.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(status.color.opacity(0.3), lineWidth: 1)
                        )
                )
            }

            // Info card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.purple)

                    Text("About Respiratory Rate")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text("Your respiratory rate is the number of breaths you take per minute. A normal resting rate for adults is 12-20 breaths per minute.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    private func getRespiratoryStatus(rate: Int) -> (label: String, description: String, color: Color) {
        switch rate {
        case 0..<12:
            return ("Below Normal", "Lower than typical range", .orange)
        case 12...20:
            return ("Normal", "Within healthy range", .green)
        default:
            return ("Above Normal", "Higher than typical range", .orange)
        }
    }
}
