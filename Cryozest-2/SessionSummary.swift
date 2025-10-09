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
                    Color.blue.opacity(0.3),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("Session Summary")
                            .foregroundColor(.white)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(.top, 26)
                        Spacer()
                    }
                    .padding(.horizontal)
                
                
                TherapyTypeView(therapyType: $therapyType, temperature: $temperature)
                
                DurationView(durationHours: $durationHours, durationMinutes: $durationMinutes, durationSeconds: $durationSeconds)
                
                TemperatureView(temperature: $temperature, therapyType: $therapyType)
                
                BodyWeightView(bodyWeight: $bodyWeight) // Adding Body Weight to Session
                
                
                HydrationSuggestionView(totalDurationInSeconds: totalDurationInSeconds, temperature: temperature, bodyWeight: bodyWeight)
                
                CalorieLossEstimationView(totalDurationInSeconds: totalDurationInSeconds, temperature: temperature, bodyWeight: bodyWeight, therapyType: therapyType)
                
                if (NoHealthDataAvailble()) {
                    NoHealthDataView()
                } else {
                    HeartRateView(label: "Average HR", heartRate: Int(averageHeartRate))
                    HeartRateView(label: "Min HR", heartRate: Int(minHeartRate))
                    HeartRateView(label: "Max HR", heartRate: Int(maxHeartRate))
                }


                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: discardSession) {
                            Text("Discard")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.red.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                        )
                                )
                        }

                        Button(action: logSession) {
                            HStack(spacing: 8) {
                                Text("Save Session")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.25))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, Color.white.opacity(0.95)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)
                            )
                            .cornerRadius(14)
                            .shadow(color: .white.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            fetchBodyWeight()
        }
    }
    
    func fetchBodyWeight() {
        HealthKitManager.shared.fetchMostRecentBodyMass { fetchedBodyWeight in
            if let fetchedBodyWeight = fetchedBodyWeight {
                self.bodyWeight = fetchedBodyWeight
            } else {
                // Set a default value for bodyWeight when the fetch fails
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
            // Handle the error here, e.g., display an error message or log the error
            print("Failed to save session: \(error.localizedDescription)")
        }
    }
    
    private func discardSession() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func NoHealthDataAvailble() -> Bool {
        return averageHeartRate == 0 || minHeartRate == 1000 || maxHeartRate == 0
    }
    
    struct NoHealthDataView: View {
        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "applewatch")
                        .foregroundColor(.orange)
                        .font(.system(size: 18))
                }

                Text("Wear Apple Watch to get heart rate metrics. Minimum 3 minute duration required.")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        }
    }
    
    struct HeartRateView: View {
        var label: String
        var heartRate: Int

        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                    Text(heartRate != 0 && heartRate != 1000 ? "\(heartRate) bpm" : "No Data")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        }
    }
    
    struct DurationView: View {
        @State var showDurationPicker = false
        @Binding var durationHours: Int
        @Binding var durationMinutes: Int
        @Binding var durationSeconds: Int
        
        var body: some View {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                Text("Duration: \(durationHours)h \(durationMinutes)m \(durationSeconds)s")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
                Button(action: { showDurationPicker.toggle() }) {
                    Text("Edit")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                        .bold()
                }
                .sheet(isPresented: $showDurationPicker) {
                    VStack {
                        Text("Choose Duration")
                            .font(.title)
                        HStack {
                            Picker("Hours", selection: $durationHours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)h")
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                            .clipped()
                            
                            Picker("Minutes", selection: $durationMinutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute)m")
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                            .clipped()
                            
                            Picker("Seconds", selection: $durationSeconds) {
                                ForEach(0..<60) { second in
                                    Text("\(second)s")
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                            .clipped()
                        }
                        Button("Done", action: { showDurationPicker.toggle() })
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        }
    }

    //Adding Body Weight output to Session Summary Screen
    struct BodyWeightView: View {
        @State var showWeightPicker = false
        @State var bodyWeightInt: Int = 0
        @Binding var bodyWeight: Double
        
        var body: some View {
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(.orange)
                Text("Body Weight: \(Int(bodyWeight)) lbs")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
                Button(action: {
                    bodyWeightInt = Int(bodyWeight)
                    showWeightPicker.toggle()
                }) {
                    Text("Edit")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                        .bold()
                }
                .sheet(isPresented: $showWeightPicker) {
                    VStack {
                        Text("Choose Weight")
                            .font(.title)
                        Picker("Weight", selection: $bodyWeightInt) {
                            ForEach(50...300, id: \.self) { weight in
                                Text("\(weight) lbs")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 150, height: 150)
                        .clipped()
                        Button("Done", action: {
                            bodyWeight = Double(bodyWeightInt)
                            showWeightPicker.toggle()
                        })
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        }
    }

    struct TemperatureView: View {
        @State var showTemperaturePicker = false
        @Binding var temperature: Int
        @Binding var therapyType: TherapyType
        
        var temperatureRange: Range<Int> {
            switch therapyType {
            case .drySauna:
                return 100..<250
            case .coldPlunge:
                return 0..<70
            case .meditation:
                return 0..<80
            case .hotYoga:
                return 70..<200
            case .coldShower:
                return 0..<70
            case .weightTraining:
                return 0..<100
            case .running:
                return 0..<100
            case .stretching:
                return 0..<100
            case .iceBath:
                return 0..<100
            case .coldYoga:
                return 0..<100
            case .deepBreathing:
                return 0..<100
            case .sleep:
                return 0..<100
            case .custom1, .custom2, .custom3, .custom4:
                return 0..<100
            default:
                return 0..<100
            }
            
        }
        
        var body: some View {
            HStack {
                Image(systemName: "thermometer")
                    .foregroundColor(.orange)
                Text("Temperature: \(temperature)°F")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
                Button(action: { showTemperaturePicker.toggle() }) {
                    Text("Edit")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                        .bold()
                }
                .sheet(isPresented: $showTemperaturePicker) {
                    VStack {
                        Text("Choose Temperature")
                            .font(.title)
                        Picker("Temperature", selection: $temperature) {
                            ForEach(temperatureRange, id: \.self) { temp in
                                Text("\(temp)°F")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 150, height: 150)
                        .clipped()
                        Button("Done", action: { showTemperaturePicker.toggle() })
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        }
    }

    struct TherapyTypeView: View {
        @Environment(\.managedObjectContext) private var managedObjectContext
        
        @Binding var therapyType: TherapyType
        @Binding var temperature: Int
        
        var body: some View {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.white)
                Text("Therapy Type: ")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                Spacer()
                
                Picker(selection: $therapyType, label: HStack {
                    Text("Therapy Type")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                        .bold()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.orange)
                }) {
                    ForEach(TherapyType.allCases) { therapyType in
                        Text(therapyType.displayName(managedObjectContext))
                            .tag(therapyType)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .accentColor(.orange)
                .onChange(of: therapyType, perform: { newValue in
                    switch newValue {
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
                })
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        }
    }

    struct HydrationSuggestionView: View {
        @State var showHydrationSuggestion = false
        @State var waterLoss: Double = 0.0
        
        var totalDurationInSeconds: TimeInterval
        var temperature: Int
        var bodyWeight: Double
        
        private func calculateWaterLoss() -> Double {
            guard bodyWeight != 0 else {
                return 0.0 // or handle the error case appropriately
            }
            
            let durationInHours = totalDurationInSeconds / 3600.0
            let temperatureAdjustment = Double(max(temperature - 70, 0)) / 10.0 * 0.10
            let waterLossPerHour = 0.5 + temperatureAdjustment
            let waterLossInLiters = (durationInHours * (0.25 * (bodyWeight/30))) * waterLossPerHour
            let waterLossInOunces = waterLossInLiters * 33.814
            return waterLossInOunces
        }
        
        var body: some View {
            let formattedWaterLoss = calculateWaterLoss()
            let roundedUpWaterLoss = Int(ceil(formattedWaterLoss))
            
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                Text("Suggested H20: \(roundedUpWaterLoss) oz")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        }
    }

    struct CalorieLossEstimationView: View {
        @State var showCalorieLossEstimation = false
        @State var calorieLoss: Double = 0.0
        
        var totalDurationInSeconds: TimeInterval
        var temperature: Int
        var bodyWeight: Double
        var therapyType: TherapyType
        
        private func calculateCalorieLoss() -> Double {
            let durationInMinutes = totalDurationInSeconds / 60.0
            let burnRatePerMinute: Double
            
            switch therapyType {
            case .drySauna:
                burnRatePerMinute = 0.89 * bodyWeight / 150.0 // 0.42 is a base rate assuming a reference weight of 150 lbs
            case .coldPlunge:
                burnRatePerMinute = 2.75 * bodyWeight / 150.0 // 2.75 is a base rate assuming a reference weight of 150 lbs
            case .meditation:
                burnRatePerMinute = 1.0 * bodyWeight / 150.0 // 1.85 is a base rate assuming a reference weight of 150 lbs
            case .hotYoga:
                burnRatePerMinute = 4.5 * bodyWeight / 150.0 // 4.5 is a base rate assuming a reference weight of 150 lbs
            case .running:
                burnRatePerMinute = 1.0 * bodyWeight / 150.0 // 1.85 is a base rate assuming a reference weight of 150 lbs
            case .stretching:
                burnRatePerMinute = 1.0 * bodyWeight / 150.0 // 1.85 is a base rate assuming a reference weight of 150 lbs
            case .weightTraining:
                burnRatePerMinute = 1.0 * bodyWeight / 150.0 // 1.85 is a base rate assuming a reference weight of 150 lbs
            case .coldShower:
                burnRatePerMinute = 1.0 * bodyWeight / 150.0 // 1.85 is a base rate assuming a reference weight of 150 lbs
            case .iceBath:
                burnRatePerMinute = 1.0 * bodyWeight / 150.0 // 1.85 is a base rate assuming a reference weight of 150 lbs
            case .coldYoga:
                burnRatePerMinute = 1.0 * bodyWeight / 150.0 // 1.85 is a base rate assuming a reference weight of 150 lbs
            case .deepBreathing:
                burnRatePerMinute = 1.0 * bodyWeight / 150.0 // 1.85 is a base rate assuming a reference weight of 150 lbs
            case .sleep:
                burnRatePerMinute = 1.0 * bodyWeight / 150.0 // 1.85 is a base rate assuming a reference weight of 150 lbs
            case .custom1, .custom2, .custom3, .custom4:
                burnRatePerMinute = 1.0 * bodyWeight / 150.0 // 1.85 is a base rate assuming a reference weight of 150 lbs
            default:
                burnRatePerMinute = 1.0 * bodyWeight / 150.0 // 1.85 is a base rate assuming a reference weight of 150 lbs
            }
            
            let tempAdjustmentFactor: Double
            if temperature > 70 {
                tempAdjustmentFactor = Double(temperature - 70) * 0.02
            } else {
                tempAdjustmentFactor = 1.0
            }
            
            let calorieLoss = durationInMinutes * burnRatePerMinute * tempAdjustmentFactor
            return calorieLoss
        }
        
        
        
        var body: some View {
            let formattedCalorieLoss = calculateCalorieLoss()
            let roundedCalorieLoss = Int(ceil(formattedCalorieLoss))
            
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                Text("Calories Lost: ~ \(roundedCalorieLoss) cal")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        }
    }

}
