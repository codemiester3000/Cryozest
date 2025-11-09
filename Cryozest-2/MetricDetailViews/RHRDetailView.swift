//
//  RHRDetailView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

struct RHRDetailView: View {
    @ObservedObject var model: RecoveryGraphModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Current value
            VStack(spacing: 8) {
                Text("Current Resting Heart Rate")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(model.mostRecentRestingHeartRate ?? 0)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.red)

                    Text("bpm")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )

            // Info card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)

                    Text("About Resting Heart Rate")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("A lower resting heart rate typically indicates better cardiovascular fitness. Elite athletes often have resting heart rates in the 40-50 bpm range.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
            )

            // Status
            let status = getRHRStatus(rhr: model.mostRecentRestingHeartRate ?? 0)
            VStack(alignment: .leading, spacing: 12) {
                Text("Fitness Level")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 12, height: 12)

                    Text(status.label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
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
        }
    }

    private func getRHRStatus(rhr: Int) -> (label: String, color: Color) {
        switch rhr {
        case 0..<40:
            return ("Athlete", .green)
        case 40..<60:
            return ("Excellent", .green)
        case 60..<70:
            return ("Good", .yellow)
        case 70..<80:
            return ("Average", .orange)
        default:
            return ("Above Average", .red)
        }
    }
}
