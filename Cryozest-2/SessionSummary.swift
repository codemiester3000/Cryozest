import SwiftUI
import CoreData

struct SessionSummary: View {
    @State private var duration: TimeInterval
    @State private var averageHeartRate: Double
    @State private var averageSpo2: Double
    @State private var averageRespirationRate: Double
    @State private var minHeartRate: Double
    @State private var maxHeartRate: Double
    @Binding private var therapyType: TherapyType
    @State private var durationHours: Int = 0
    @State private var durationMinutes: Int = 0
    @State private var durationSeconds: Int = 0
    @State private var temperature: Int = 70
    @State private var bodyWeight: Double = 150
    @State private var showDurationPicker = false
    @State private var showTemperaturePicker = false
    @State private var waterLoss: Double = 0.0
    @State private var hydrationSuggestion: Double = 0.0

    private var hasHealthData: Bool {
        return averageHeartRate != 0 && minHeartRate != 1000 && maxHeartRate != 0
    }

    let healthKitManager = HealthKitManager.shared

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext

    init(duration: TimeInterval, therapyType: Binding<TherapyType>, averageHeartRate: Double, averageSpo2: Double, averageRespirationRate: Double, minHeartRate: Double, maxHeartRate: Double) {
        self._duration = State(initialValue: duration)
        self._therapyType = therapyType
        self._averageHeartRate = State(initialValue: averageHeartRate)
        self._averageSpo2 = State(initialValue: averageSpo2)
        self._averageRespirationRate = State(initialValue: averageRespirationRate)
        self._minHeartRate = State(initialValue: minHeartRate)
        self._maxHeartRate = State(initialValue: maxHeartRate)

        let (hours, minutes, seconds) = secondsToHoursMinutesSeconds(seconds: Int(duration))
        self._durationHours = State(initialValue: hours)
        self._durationMinutes = State(initialValue: minutes)
        self._durationSeconds = State(initialValue: seconds)

        let initialTemperature: Int
        switch therapyType.wrappedValue {
        case .drySauna:
            initialTemperature = 165
        case .coldPlunge:
            initialTemperature = 50
        case .meditation:
            initialTemperature = 60
        case .hotYoga:
            initialTemperature = 110
        default:
            initialTemperature = 70
        }
        self._temperature = State(initialValue: initialTemperature)
    }

    private var totalDurationInSeconds: TimeInterval {
        return TimeInterval((durationHours * 3600) + (durationMinutes * 60) + durationSeconds)
    }

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle gradient overlay
            RadialGradient(
                gradient: Gradient(colors: [
                    therapyType.color.opacity(0.2),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Session Summary")
                            .foregroundColor(.white)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Hero Card - Therapy Type & Duration
                    VStack(spacing: 20) {
                        // Therapy icon and name
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                therapyType.color.opacity(0.8),
                                                therapyType.color.opacity(0.5)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)

                                Image(systemName: therapyType.icon)
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(.white)
                            }

                            TherapyTypePickerButton(therapyType: $therapyType, temperature: $temperature)
                        }

                        // Duration Display
                        VStack(spacing: 8) {
                            Text("Duration")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))

                            HStack(spacing: 4) {
                                Text("\(durationHours)h")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("\(durationMinutes)m")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                if durationSeconds > 0 {
                                    Text("\(durationSeconds)s")
                                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.top, 12)
                                }
                            }

                            Button(action: { showDurationPicker.toggle() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Edit Duration")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(therapyType.color)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(therapyType.color.opacity(0.15))
                                )
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 32)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.12),
                                        Color.white.opacity(0.06)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                therapyType.color.opacity(0.4),
                                                therapyType.color.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    )
                    .shadow(color: therapyType.color.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 20)

                    // Stats Grid
                    VStack(spacing: 16) {
                        // Row 1: Temperature & Body Weight
                        HStack(spacing: 16) {
                            ModernStatCard(
                                icon: "thermometer.medium",
                                label: "Temperature",
                                value: "\(temperature)°F",
                                color: temperature > 100 ? .orange : .cyan,
                                onEdit: { showTemperaturePicker.toggle() }
                            )

                            ModernStatCard(
                                icon: "scalemass.fill",
                                label: "Body Weight",
                                value: "\(Int(bodyWeight)) lbs",
                                color: .purple,
                                onEdit: nil
                            )
                        }

                        // Row 2: Hydration & Calories
                        HStack(spacing: 16) {
                            ModernStatCard(
                                icon: "drop.fill",
                                label: "Hydration",
                                value: "\(calculateHydration()) oz",
                                color: .blue,
                                onEdit: nil
                            )

                            ModernStatCard(
                                icon: "flame.fill",
                                label: "Calories",
                                value: "~\(calculateCalories()) cal",
                                color: .red,
                                onEdit: nil
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Heart Rate Section
                    if hasHealthData {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Heart Rate")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)

                            HeartRateRangeCard(
                                average: Int(averageHeartRate),
                                min: Int(minHeartRate),
                                max: Int(maxHeartRate)
                            )
                            .padding(.horizontal, 20)
                        }
                    } else {
                        NoHealthDataCard()
                            .padding(.horizontal, 20)
                    }

                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: discardSession) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("Discard")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.red.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.red.opacity(0.4), lineWidth: 2)
                                    )
                            )
                        }

                        Button(action: logSession) {
                            HStack(spacing: 8) {
                                Text("Save Session")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                            }
                            .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.25))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white,
                                        Color.white.opacity(0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .white.opacity(0.4), radius: 15, x: 0, y: 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showDurationPicker) {
            DurationPickerSheet(
                hours: $durationHours,
                minutes: $durationMinutes,
                seconds: $durationSeconds
            )
        }
        .sheet(isPresented: $showTemperaturePicker) {
            TemperaturePickerSheet(
                temperature: $temperature,
                therapyType: therapyType
            )
        }
        .onAppear {
            fetchBodyWeight()
        }
    }

    // MARK: - Helper Functions

    func fetchBodyWeight() {
        HealthKitManager.shared.fetchMostRecentBodyMass { fetchedBodyWeight in
            if let fetchedBodyWeight = fetchedBodyWeight {
                self.bodyWeight = fetchedBodyWeight
            } else {
                self.bodyWeight = 150
            }
        }
    }

    func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int, Int) {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = (seconds % 3600) % 60
        return (hours, minutes, seconds)
    }

    func calculateHydration() -> Int {
        guard bodyWeight != 0 else { return 0 }
        let durationInHours = totalDurationInSeconds / 3600.0
        let temperatureAdjustment = Double(max(temperature - 70, 0)) / 10.0 * 0.10
        let waterLossPerHour = 0.5 + temperatureAdjustment
        let waterLossInLiters = (durationInHours * (0.25 * (bodyWeight/30))) * waterLossPerHour
        let waterLossInOunces = waterLossInLiters * 33.814
        return Int(ceil(waterLossInOunces))
    }

    func calculateCalories() -> Int {
        let durationInMinutes = totalDurationInSeconds / 60.0
        let burnRatePerMinute: Double

        switch therapyType {
        case .drySauna:
            burnRatePerMinute = 0.89 * bodyWeight / 150.0
        case .coldPlunge:
            burnRatePerMinute = 2.75 * bodyWeight / 150.0
        case .meditation:
            burnRatePerMinute = 1.0 * bodyWeight / 150.0
        case .hotYoga:
            burnRatePerMinute = 4.5 * bodyWeight / 150.0
        default:
            burnRatePerMinute = 1.0 * bodyWeight / 150.0
        }

        let tempAdjustmentFactor: Double
        if temperature > 70 {
            tempAdjustmentFactor = Double(temperature - 70) * 0.02
        } else {
            tempAdjustmentFactor = 1.0
        }

        let calorieLoss = durationInMinutes * burnRatePerMinute * tempAdjustmentFactor
        return Int(ceil(calorieLoss))
    }

    private func logSession() {
        let newSession = TherapySessionEntity(context: viewContext)
        newSession.date = Date()
        newSession.duration = totalDurationInSeconds
        newSession.temperature = Double(temperature)
        newSession.therapyType = therapyType.rawValue
        newSession.id = UUID()
        newSession.averageHeartRate = averageHeartRate
        newSession.averageSpo2 = averageSpo2
        newSession.averageRespirationRate = averageRespirationRate
        newSession.minHeartRate = minHeartRate
        newSession.maxHeartRate = maxHeartRate
        newSession.bodyWeight = bodyWeight

        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save session: \(error.localizedDescription)")
        }
    }

    private func discardSession() {
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Modern Components

struct ModernStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let onEdit: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if let onEdit = onEdit {
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(color)
                }
            } else {
                Spacer()
                    .frame(height: 18)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct HeartRateRangeCard: View {
    let average: Int
    let min: Int
    let max: Int

    var normalizedMin: CGFloat {
        guard max > min else { return 0 }
        return CGFloat(min - min) / CGFloat(max - min)
    }

    var normalizedAverage: CGFloat {
        guard max > min else { return 0.5 }
        return CGFloat(average - min) / CGFloat(max - min)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Average Heart Rate - Prominent Display
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.3),
                                    Color.red.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Average")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(average)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("bpm")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()
            }

            // Heart Rate Range Visualization
            VStack(spacing: 12) {
                // Range Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 12)

                        // Active range
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.red.opacity(0.4),
                                        Color.red.opacity(0.7),
                                        Color.red
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width, height: 12)

                        // Average indicator
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .shadow(color: .red.opacity(0.5), radius: 4, x: 0, y: 2)
                            .offset(x: normalizedAverage * (geometry.size.width - 20))
                    }
                }
                .frame(height: 20)

                // Min and Max labels
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MIN")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(min) bpm")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("MAX")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(max) bpm")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.red.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

struct NoHealthDataCard: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: "applewatch")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("No Heart Rate Data")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Wear Apple Watch during your session to track heart rate metrics (minimum 3 minutes)")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                )
        )
    }
}

struct TherapyTypePickerButton: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Binding var therapyType: TherapyType
    @Binding var temperature: Int

    var body: some View {
        Menu {
            ForEach(TherapyType.allCases) { type in
                Button(action: {
                    therapyType = type
                    updateTemperature(for: type)
                }) {
                    HStack {
                        Image(systemName: type.icon)
                        Text(type.displayName(managedObjectContext))
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(therapyType.displayName(managedObjectContext))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
            )
        }
    }

    func updateTemperature(for type: TherapyType) {
        switch type {
        case .drySauna:
            temperature = 165
        case .coldPlunge:
            temperature = 50
        case .meditation:
            temperature = 60
        case .hotYoga:
            temperature = 110
        default:
            temperature = 70
        }
    }
}

struct DurationPickerSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.2, blue: 0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Text("Edit Duration")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 40)

                HStack(spacing: 20) {
                    VStack {
                        Text("Hours")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 150)
                        .clipped()
                    }

                    VStack {
                        Text("Minutes")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 150)
                        .clipped()
                    }

                    VStack {
                        Text("Seconds")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 150)
                        .clipped()
                    }
                }

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Done")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.25))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct TemperaturePickerSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var temperature: Int
    let therapyType: TherapyType

    var temperatureRange: Range<Int> {
        switch therapyType {
        case .drySauna:
            return 100..<250
        case .coldPlunge, .coldShower:
            return 0..<70
        case .hotYoga:
            return 70..<200
        default:
            return 0..<100
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.2, blue: 0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Text("Edit Temperature")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 40)

                Picker("Temperature", selection: $temperature) {
                    ForEach(temperatureRange, id: \.self) { temp in
                        Text("\(temp)°F").tag(temp)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 200)
                .clipped()

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Done")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.25))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}
