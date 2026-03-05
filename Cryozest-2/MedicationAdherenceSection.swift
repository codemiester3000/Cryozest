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

        // Only count medications that were created on or before this date
        let relevantMedications = activeMedications.filter { medication in
            if let createdDate = medication.createdDate {
                return date >= createdDate
            }
            return false
        }

        guard !relevantMedications.isEmpty else { return .noData }

        var takenCount = 0
        for medication in relevantMedications {
            if let medId = medication.id,
               MedicationIntake.wasTaken(medicationId: medId, on: date, context: viewContext) {
                takenCount += 1
            }
        }

        let percentage = Double(takenCount) / Double(relevantMedications.count)
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
                // Only count days after medication was created
                if let createdDate = medication.createdDate, date >= createdDate {
                    totalExpected += 1
                    if let medId = medication.id,
                       MedicationIntake.wasTaken(medicationId: medId, on: date, context: viewContext) {
                        totalTaken += 1
                    }
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

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    // Get the month range being displayed
    private var dateRangeText: String {
        guard let firstDate = days.first,
              let lastDate = days.last else {
            return ""
        }

        let calendar = Calendar.current
        let firstMonth = calendar.component(.month, from: firstDate)
        let lastMonth = calendar.component(.month, from: lastDate)
        let firstYear = calendar.component(.year, from: firstDate)
        let lastYear = calendar.component(.year, from: lastDate)

        if firstMonth == lastMonth && firstYear == lastYear {
            return monthYearFormatter.string(from: firstDate)
        } else if firstYear == lastYear {
            return "\(monthFormatter.string(from: firstDate)) - \(monthYearFormatter.string(from: lastDate))"
        } else {
            return "\(monthYearFormatter.string(from: firstDate)) - \(monthYearFormatter.string(from: lastDate))"
        }
    }

    // Group dates by month
    private var datesByMonth: [(monthLabel: String, dates: [Date])] {
        let calendar = Calendar.current
        var grouped: [(String, [Date])] = []

        for date in days {
            let monthLabel = monthYearFormatter.string(from: date)

            if let lastIndex = grouped.indices.last, grouped[lastIndex].0 == monthLabel {
                grouped[lastIndex].1.append(date)
            } else {
                grouped.append((monthLabel, [date]))
            }
        }

        return grouped
    }

    var body: some View {
        VStack(spacing: 12) {
            // Date range header
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Text(dateRangeText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            // Heatmap grid - organized by month
            VStack(spacing: 4) {
                ForEach(Array(datesByMonth.enumerated()), id: \.offset) { monthIndex, monthGroup in
                    VStack(spacing: 6) {
                        // Month label and divider
                        HStack(spacing: 8) {
                            Text(monthGroup.monthLabel)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )

                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 1)
                        }
                        .padding(.top, monthIndex > 0 ? 12 : 0)

                        // Day labels for this month
                        HStack(spacing: 4) {
                            ForEach(0..<min(7, monthGroup.dates.count), id: \.self) { col in
                                Text(String(dayFormatter.string(from: monthGroup.dates[col]).prefix(1)))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                            }
                            if monthGroup.dates.count < 7 {
                                ForEach(monthGroup.dates.count..<7, id: \.self) { _ in
                                    Color.clear.frame(maxWidth: .infinity)
                                }
                            }
                        }

                        // Grid for this month's dates
                        let monthRows = Int(ceil(Double(monthGroup.dates.count) / Double(columns)))
                        VStack(spacing: 4) {
                            ForEach(0..<monthRows, id: \.self) { row in
                                HStack(spacing: 4) {
                                    ForEach(0..<columns, id: \.self) { col in
                                        let index = row * columns + col
                                        if index < monthGroup.dates.count {
                                            let date = monthGroup.dates[index]
                                            let adherence = getAdherence(date)
                                            let isToday = Calendar.current.isDateInToday(date)
                                            let dayNumber = Calendar.current.component(.day, from: date)

                                            ZStack {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(adherence.color)
                                                    .frame(height: 32)

                                                // Day number
                                                Text("\(dayNumber)")
                                                    .font(.system(size: 9, weight: .semibold))
                                                    .foregroundColor(adherence != .noData ? Color.white : Color.white.opacity(0.3))

                                                // Today indicator ring
                                                if isToday {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(Color.white, lineWidth: 2)
                                                        .frame(height: 32)
                                                }
                                            }
                                        } else {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.clear)
                                                .frame(height: 32)
                                        }
                                    }
                                }
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

        // Show no data for days before medication was created
        if let createdDate = medication.createdDate, date < createdDate {
            return .noData
        }

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

        // Only count days after medication was created
        guard let createdDate = medication.createdDate else { return 0 }
        let relevantDays = last30Days.filter { $0 >= createdDate }

        guard !relevantDays.isEmpty else { return 0 }

        var taken = 0
        for date in relevantDays {
            if MedicationIntake.wasTaken(medicationId: medId, on: date, context: viewContext) {
                taken += 1
            }
        }

        return Int((Double(taken) / Double(relevantDays.count)) * 100)
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
