//
//  HabitImpactChips.swift
//  Cryozest-2
//
//  Compact impact summary tags for each habit's health correlations
//

import SwiftUI

struct HabitImpactChips: View {
    let impacts: [HabitImpact]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(impacts) { impact in
                HStack(spacing: 3) {
                    Text(abbreviatedMetric(impact.metricName))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text(impact.changeDescription)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(impact.isPositive ? .green : .red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(impact.isPositive ?
                              Color.green.opacity(0.12) :
                              Color.red.opacity(0.12))
                )
            }
        }
    }

    private func abbreviatedMetric(_ name: String) -> String {
        switch name {
        case "Sleep Duration": return "Sleep"
        case "Pain Level": return "Pain"
        default: return name
        }
    }
}
