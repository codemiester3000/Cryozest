import SwiftUI

struct WhatsWorkingPill: View {
    let impact: HabitImpact
    let isEarlySignal: Bool
    let onTap: () -> Void

    @Environment(\.managedObjectContext) private var viewContext

    private var habitName: String {
        impact.habitType.displayName(viewContext)
    }

    private var metricLabel: String {
        switch impact.metricName {
        case "Sleep Duration": return "Sleep"
        default: return impact.metricName
        }
    }

    private var changeText: String {
        let pct = abs(Int(impact.percentageChange))
        // RHR: lower is better, so show "down" for positive impact
        if impact.metricName == "RHR" && impact.isPositive {
            return "↓\(pct)%"
        }
        return impact.isPositive ? "+\(pct)%" : "-\(pct)%"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: impact.habitType.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(impact.habitType.color)

                Text(habitName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Text("→")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))

                Text("\(metricLabel) \(changeText)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)

                if isEarlySignal {
                    HStack(spacing: 2) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 6, weight: .bold))
                        Text("Early")
                            .font(.system(size: 7, weight: .bold))
                            .textCase(.uppercase)
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(Color.cyan.opacity(0.15))
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(impact.habitType.color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
