import SwiftUI
import CoreData

struct ProjectionsView: View {
    let projectionsByHabit: [TherapyType: [HealthProjection]]
    @State private var selectedHabit: TherapyType?
    @Environment(\.managedObjectContext) private var viewContext

    private let cardBg = Color(red: 0.10, green: 0.14, blue: 0.22)

    var availableHabits: [TherapyType] {
        Array(projectionsByHabit.keys).sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if availableHabits.isEmpty {
                    emptyState
                } else {
                    habitPicker
                    if let habit = selectedHabit ?? availableHabits.first,
                       let projections = projectionsByHabit[habit], !projections.isEmpty {
                        projectionCards(projections)
                        disclaimer
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .onAppear {
            if selectedHabit == nil {
                selectedHabit = availableHabits.first
            }
        }
    }

    // MARK: - Habit Picker

    private var habitPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableHabits, id: \.self) { habit in
                    let isSelected = (selectedHabit ?? availableHabits.first) == habit
                    Button(action: { selectedHabit = habit }) {
                        HStack(spacing: 6) {
                            Image(systemName: habit.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(habit.displayName(viewContext))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? habit.color.opacity(0.3) : Color.white.opacity(0.06))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Projection Cards

    private func projectionCards(_ projections: [HealthProjection]) -> some View {
        VStack(spacing: 12) {
            ForEach(projections) { projection in
                projectionCard(projection)
            }
        }
    }

    private func projectionCard(_ projection: HealthProjection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: metric name + confidence
            HStack {
                Text(projection.metric)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                confidenceBadge(projection.confidence)
            }

            // Current → Projected
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Current")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    Text(formatValue(projection.currentValue, metric: projection.metric))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)

                // Arrow
                VStack(spacing: 2) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("30 days")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(width: 60)

                VStack(spacing: 4) {
                    Text("Projected")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    Text(formatValue(projection.projectedValue, metric: projection.metric))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(projection.isPositiveDirection ? .green : .red)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)

            // Change badge
            HStack(spacing: 6) {
                Image(systemName: projection.isPositiveDirection ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 10, weight: .bold))

                let sign = projection.projectedChange >= 0 ? "+" : ""
                Text("\(sign)\(Int(projection.projectedChange))% from baseline")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(projection.isPositiveDirection ? .green : .red)

            // Explanation
            Text(projection.explanation)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func confidenceBadge(_ level: ConfidenceLevel) -> some View {
        let color: Color = {
            switch level {
            case .high: return .green
            case .moderate: return .cyan
            case .earlySignal: return .yellow
            case .low: return .orange
            case .insufficient: return .gray
            }
        }()

        return Text(level.rawValue)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.white.opacity(0.2))

            Text("Not Enough Data Yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))

            Text("Track habits for at least 2 weeks with consistent health data to see projections.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 11, weight: .medium))
            Text("Projections based on your personal data patterns. Not medical advice.")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.25))
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func formatValue(_ value: Double, metric: String) -> String {
        switch metric {
        case "HRV": return "\(Int(value))ms"
        case "RHR", "Resting Heart Rate": return "\(Int(value))bpm"
        case "Sleep Duration": return String(format: "%.1fh", value)
        default: return String(format: "%.1f", value)
        }
    }
}
