import SwiftUI
import HealthKit
import Charts

struct SessionRow: View {
    var session: TherapySessionEntity
    var therapyTypeSelection: TherapyTypeSelection
    var therapyTypeName: String

    @State private var showingDeleteAlert = false
    @State private var isExpanded = false

    // Health data states
    @State private var heartRateData: [HeartRateDataPoint] = []
    @State private var avgHeartRate: Double?
    @State private var minHeartRate: Double?
    @State private var maxHeartRate: Double?
    @State private var avgHRV: Double?
    @State private var calories: Double?
    @State private var activeEnergy: Double?
    @State private var respiratoryRate: Double?
    @State private var spo2: Double?
    @State private var isLoadingHealthData = false

    @Environment(\.managedObjectContext) private var managedObjectContext

    struct HeartRateDataPoint: Identifiable {
        let id = UUID()
        let timestamp: Date
        let bpm: Double
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Left accent bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                therapyTypeSelection.selectedTherapyType.color,
                                therapyTypeSelection.selectedTherapyType.color.opacity(0.6)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 12) {
                // Header: Date and badges
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                        Text(formattedDate)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Apple Watch badge (if applicable)
                    if session.isAppleWatch {
                        HStack(spacing: 4) {
                            Image(systemName: "applewatch")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Auto")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.15))
                        )
                    }

                    // Delete button
                    Button(action: {
                        self.showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.12))
                            )
                    }
                }

                // Main info: Duration and time
                HStack(alignment: .center, spacing: 16) {
                    // Duration - prominent display
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Duration")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text(compactDuration)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }

                    Spacer()

                    // Time of day
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Time")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text(formattedTime)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                // Session streak indicator (if multiple sessions on same day)
                if let streakCount = calculateDayStreak(), streakCount > 1 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                        Text("\(streakCount) sessions today")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                    )
                }

                // Expand indicator
                HStack {
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.top, 4)
            }
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
        }

        // Expanded content
        if isExpanded {
            expandedContent
                .transition(.opacity.combined(with: .move(edge: .top)))
                .onAppear {
                    if session.isAppleWatch {
                        loadHealthData()
                    }
                }
        }
    }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(therapyTypeSelection.selectedTherapyType.color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Session?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteSession()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func deleteSession() {
        managedObjectContext.delete(session)
        try? managedObjectContext.save()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(session.date ?? Date()) {
            return "Today"
        } else if calendar.isDateInYesterday(session.date ?? Date()) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: session.date ?? Date())
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: session.date ?? Date())
    }

    private var compactDuration: String {
        let totalMinutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60

        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else if totalMinutes > 0 {
            return seconds > 0 ? "\(totalMinutes)m \(seconds)s" : "\(totalMinutes)m"
        } else {
            return "\(seconds)s"
        }
    }

    private var formattedDuration: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        return minutes == 0 ? "\(seconds) secs" : "\(minutes) mins \(seconds) secs"
    }

    private func calculateDayStreak() -> Int? {
        // This would require access to all sessions for the day
        // For now, return nil - can be implemented with a fetch request if needed
        return nil
    }

    private func loadHealthData() {
        guard let sessionDate = session.date else { return }

        DispatchQueue.main.async {
            self.isLoadingHealthData = true
        }

        let startDate = sessionDate
        let endDate = sessionDate.addingTimeInterval(session.duration)

        let dispatchGroup = DispatchGroup()

        // Fetch Heart Rate Data
        dispatchGroup.enter()
        HealthKitManager.shared.fetchHeartRateData(from: startDate, to: endDate) { samples, error in
            if let samples = samples, !samples.isEmpty {
                let dataPoints = samples.map { sample in
                    HeartRateDataPoint(
                        timestamp: sample.startDate,
                        bpm: sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    )
                }

                let sortedData = dataPoints.sorted { $0.timestamp < $1.timestamp }
                let bpms = dataPoints.map { $0.bpm }
                let avg = bpms.reduce(0, +) / Double(bpms.count)
                let min = bpms.min()
                let max = bpms.max()

                DispatchQueue.main.async {
                    self.heartRateData = sortedData
                    self.avgHeartRate = avg
                    self.minHeartRate = min
                    self.maxHeartRate = max
                }
            }
            dispatchGroup.leave()
        }

        // Fetch HRV Data
        dispatchGroup.enter()
        HealthKitManager.shared.fetchHRVData(from: startDate, to: endDate) { samples, error in
            if let samples = samples, !samples.isEmpty {
                let hrvValues = samples.map { $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) }
                let avg = hrvValues.reduce(0, +) / Double(hrvValues.count)
                DispatchQueue.main.async {
                    self.avgHRV = avg
                }
            }
            dispatchGroup.leave()
        }

        // Fetch Active Energy
        dispatchGroup.enter()
        HealthKitManager.shared.fetchActiveEnergy(from: startDate, to: endDate) { samples, error in
            if let samples = samples, !samples.isEmpty {
                let totalEnergy = samples.reduce(0.0) { sum, sample in
                    sum + sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                }
                DispatchQueue.main.async {
                    self.activeEnergy = totalEnergy
                }
            }
            dispatchGroup.leave()
        }

        // Fetch Total Calories (combining active + basal for duration)
        dispatchGroup.enter()
        HealthKitManager.shared.fetchTotalCalories(from: startDate, to: endDate) { total, error in
            if let total = total {
                DispatchQueue.main.async {
                    self.calories = total
                }
            }
            dispatchGroup.leave()
        }

        // Fetch Respiratory Rate
        dispatchGroup.enter()
        HealthKitManager.shared.fetchRespiratoryRate(from: startDate, to: endDate) { samples, error in
            if let samples = samples, !samples.isEmpty {
                let rates = samples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
                let avg = rates.reduce(0, +) / Double(rates.count)
                DispatchQueue.main.async {
                    self.respiratoryRate = avg
                }
            }
            dispatchGroup.leave()
        }

        // Fetch SpO2
        dispatchGroup.enter()
        HealthKitManager.shared.fetchOxygenSaturation(from: startDate, to: endDate) { samples, error in
            if let samples = samples, !samples.isEmpty {
                let values = samples.map { $0.quantity.doubleValue(for: HKUnit.percent()) }
                let avg = values.reduce(0, +) / Double(values.count)
                DispatchQueue.main.async {
                    self.spo2 = avg
                }
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            self.isLoadingHealthData = false
        }
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(therapyTypeSelection.selectedTherapyType.color.opacity(0.3))
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 16) {
                if session.isAppleWatch {
                    if isLoadingHealthData {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(therapyTypeSelection.selectedTherapyType.color)
                            Text("Loading health data...")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                        }
                        .padding()
                    } else if !heartRateData.isEmpty || avgHRV != nil || calories != nil {
                        // Heart Rate Chart
                        if !heartRateData.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Heart Rate")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                                    .textCase(.uppercase)
                                    .tracking(0.8)

                                Chart(heartRateData) { dataPoint in
                                    LineMark(
                                        x: .value("Time", dataPoint.timestamp),
                                        y: .value("BPM", dataPoint.bpm)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.red, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                                    AreaMark(
                                        x: .value("Time", dataPoint.timestamp),
                                        y: .value("BPM", dataPoint.bpm)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.red.opacity(0.3), .pink.opacity(0.1)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }
                                .chartYAxis {
                                    AxisMarks(position: .leading) { value in
                                        AxisValueLabel()
                                            .foregroundStyle(.white.opacity(0.6))
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks { value in
                                        AxisValueLabel(format: .dateTime.minute())
                                            .foregroundStyle(.white.opacity(0.6))
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                }
                                .frame(height: 140)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                )

                                // Heart Rate Stats
                                HStack(spacing: 12) {
                                    if let avg = avgHeartRate {
                                        MetricBadge(title: "AVG", value: "\(Int(avg))", unit: "bpm", color: .red)
                                    }
                                    if let min = minHeartRate {
                                        MetricBadge(title: "MIN", value: "\(Int(min))", unit: "bpm", color: .blue)
                                    }
                                    if let max = maxHeartRate {
                                        MetricBadge(title: "MAX", value: "\(Int(max))", unit: "bpm", color: .orange)
                                    }
                                }
                            }
                        }

                        // Health Metrics Grid
                        if avgHRV != nil || calories != nil || activeEnergy != nil || respiratoryRate != nil || spo2 != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Health Metrics")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                                    .textCase(.uppercase)
                                    .tracking(0.8)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    if let hrv = avgHRV {
                                        HealthMetricCard(
                                            icon: "waveform.path.ecg",
                                            title: "HRV",
                                            value: String(format: "%.0f", hrv),
                                            unit: "ms",
                                            color: .purple
                                        )
                                    }

                                    if let cal = calories {
                                        HealthMetricCard(
                                            icon: "flame.fill",
                                            title: "Calories",
                                            value: String(format: "%.0f", cal),
                                            unit: "kcal",
                                            color: .orange
                                        )
                                    }

                                    if let active = activeEnergy {
                                        HealthMetricCard(
                                            icon: "bolt.fill",
                                            title: "Active Energy",
                                            value: String(format: "%.0f", active),
                                            unit: "kcal",
                                            color: .green
                                        )
                                    }

                                    if let rr = respiratoryRate {
                                        HealthMetricCard(
                                            icon: "lungs.fill",
                                            title: "Resp. Rate",
                                            value: String(format: "%.0f", rr),
                                            unit: "br/min",
                                            color: .cyan
                                        )
                                    }

                                    if let oxygen = spo2 {
                                        HealthMetricCard(
                                            icon: "o.circle.fill",
                                            title: "Blood O₂",
                                            value: String(format: "%.0f", oxygen * 100),
                                            unit: "%",
                                            color: .blue
                                        )
                                    }
                                }
                            }
                        }
                    } else {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "heart.slash")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.4))
                                Text("No health data available")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                        }
                        .padding()
                    }
                } else {
                    // Manual session - show simple info
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.cyan)
                        Text("Manually logged session - no health data available")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cyan.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Helper Views

struct MetricBadge: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(color.opacity(0.8))
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(unit)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct HealthMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(unit)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
