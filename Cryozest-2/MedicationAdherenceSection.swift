//
//  MedicationAdherenceSection.swift
//  Cryozest-2
//
//  Medication adherence heatmap for Insights tab
//

import SwiftUI
import CoreData

struct MedicationAdherenceSection: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: Medication.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Medication.createdDate, ascending: true)]
    )
    private var allMedications: FetchedResults<Medication>

    @State private var expandedMedications: Set<UUID> = []

    private var activeMedications: [Medication] {
        allMedications.filter { $0.isActive }
    }

    // Get last 30 days
    private var last30Days: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today)
        }.reversed()
    }

    // Calculate overall adherence for a specific day
    private func overallAdherence(for date: Date) -> AdherenceLevel {
        guard !activeMedications.isEmpty else { return .noData }

        var takenCount = 0
        for medication in activeMedications {
            if let medId = medication.id,
               MedicationIntake.wasTaken(medicationId: medId, on: date, context: viewContext) {
                takenCount += 1
            }
        }

        let percentage = Double(takenCount) / Double(activeMedications.count)
        if percentage == 1.0 {
            return .perfect
        } else if percentage > 0 {
            return .partial
        } else {
            return .missed
        }
    }

    // Calculate overall adherence percentage for last 30 days
    private var overallAdherencePercentage: Int {
        guard !activeMedications.isEmpty else { return 0 }

        var totalExpected = 0
        var totalTaken = 0

        for date in last30Days {
            for medication in activeMedications {
                totalExpected += 1
                if let medId = medication.id,
                   MedicationIntake.wasTaken(medicationId: medId, on: date, context: viewContext) {
                    totalTaken += 1
                }
            }
        }

        guard totalExpected > 0 else { return 0 }
        return Int((Double(totalTaken) / Double(totalExpected)) * 100)
    }

    private var daysWithPerfectAdherence: Int {
        last30Days.filter { overallAdherence(for: $0) == .perfect }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            InsightsSectionHeader(
                title: "Medication Adherence",
                icon: "pills.fill",
                color: .green
            )
            .padding(.horizontal)

            if activeMedications.isEmpty {
                InsightsEmptyStateCard(
                    title: "No Medications Tracked",
                    message: "Add medications on the Daily tab to see your adherence patterns here.",
                    icon: "pills"
                )
                .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Overall heatmap
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 30 Days")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))

                        // Calendar heatmap
                        AdherenceHeatmap(
                            days: last30Days,
                            getAdherence: overallAdherence
                        )

                        // Stats
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(overallAdherencePercentage)%")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.green)

                                Text("Overall adherence")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Divider()
                                .frame(height: 40)
                                .background(Color.white.opacity(0.2))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(daysWithPerfectAdherence)")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.cyan)

                                Text("Perfect days")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, 8)

                        // Legend
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 16) {
                                LegendItem(color: .green, label: "All taken")
                                LegendItem(color: .orange, label: "Some taken")
                                LegendItem(color: .red.opacity(0.6), label: "None taken")
                            }

                            HStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.green)
                                        .frame(width: 12, height: 12)

                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.white, lineWidth: 1.5)
                                        .frame(width: 12, height: 12)
                                }

                                Text("White border = Today")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )

                    // Individual medications
                    VStack(spacing: 12) {
                        ForEach(activeMedications, id: \.id) { medication in
                            IndividualMedicationCard(
                                medication: medication,
                                last30Days: last30Days,
                                isExpanded: expandedMedications.contains(medication.id ?? UUID()),
                                onToggleExpand: {
                                    if let medId = medication.id {
                                        if expandedMedications.contains(medId) {
                                            expandedMedications.remove(medId)
                                        } else {
                                            expandedMedications.insert(medId)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

enum AdherenceLevel {
    case perfect
    case partial
    case missed
    case noData

    var color: Color {
        switch self {
        case .perfect: return .green
        case .partial: return .orange
        case .missed: return .red.opacity(0.6)
        case .noData: return Color.white.opacity(0.1)
        }
    }
}

struct AdherenceHeatmap: View {
    let days: [Date]
    let getAdherence: (Date) -> AdherenceLevel

    private let columns = 7
    private var rows: Int {
        Int(ceil(Double(days.count) / Double(columns)))
    }

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 8) {
            // Day labels - use first 7 days from the array to get correct weekdays
            HStack(spacing: 0) {
                ForEach(0..<min(7, days.count), id: \.self) { col in
                    Text(String(dayFormatter.string(from: days[col]).prefix(1)))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }

            // Heatmap grid
            VStack(spacing: 4) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<columns, id: \.self) { col in
                            let index = row * columns + col
                            if index < days.count {
                                let date = days[index]
                                let adherence = getAdherence(date)
                                let isToday = Calendar.current.isDateInToday(date)

                                ZStack {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(adherence.color)
                                        .frame(height: 16)

                                    // Today indicator ring
                                    if isToday {
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(height: 16)
                                    }
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.clear)
                                    .frame(height: 16)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

struct IndividualMedicationCard: View {
    @Environment(\.managedObjectContext) private var viewContext

    let medication: Medication
    let last30Days: [Date]
    let isExpanded: Bool
    let onToggleExpand: () -> Void

    // Calculate adherence for this specific medication
    private func adherence(for date: Date) -> AdherenceLevel {
        guard let medId = medication.id else { return .noData }

        if MedicationIntake.wasTaken(medicationId: medId, on: date, context: viewContext) {
            return .perfect
        } else {
            return .missed
        }
    }

    // Calculate current streak
    private var currentStreak: Int {
        guard let medId = medication.id else { return 0 }

        var streak = 0
        let calendar = Calendar.current

        for dayOffset in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { break }

            if MedicationIntake.wasTaken(medicationId: medId, on: date, context: viewContext) {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    // Calculate best streak
    private var bestStreak: Int {
        guard let medId = medication.id else { return 0 }

        var maxStreak = 0
        var currentCount = 0
        let calendar = Calendar.current

        // Check last 90 days
        for dayOffset in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            if MedicationIntake.wasTaken(medicationId: medId, on: date, context: viewContext) {
                currentCount += 1
                maxStreak = max(maxStreak, currentCount)
            } else {
                currentCount = 0
            }
        }

        return maxStreak
    }

    private var adherencePercentage: Int {
        guard let medId = medication.id else { return 0 }

        var taken = 0
        for date in last30Days {
            if MedicationIntake.wasTaken(medicationId: medId, on: date, context: viewContext) {
                taken += 1
            }
        }

        return Int((Double(taken) / Double(last30Days.count)) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.2))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(medication.name ?? "Medication")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Text("\(adherencePercentage)% adherence")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(adherencePercentage >= 80 ? .green : .orange)
                    }
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Mini heatmap
                    AdherenceHeatmap(
                        days: last30Days,
                        getAdherence: adherence
                    )

                    // Streaks
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("🔥")
                                    .font(.system(size: 18))
                                Text("\(currentStreak)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.orange)
                            }

                            Text("Current streak")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Divider()
                            .frame(height: 30)
                            .background(Color.white.opacity(0.2))

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("⭐️")
                                    .font(.system(size: 18))
                                Text("\(bestStreak)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.yellow)
                            }

                            Text("Best streak")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleExpand()
        }
    }
}
