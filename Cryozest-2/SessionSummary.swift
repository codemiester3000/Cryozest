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
    }
    
    private var totalDurationInSeconds: TimeInterval {
        return TimeInterval((durationHours * 3600) + (durationMinutes * 60) + durationSeconds)
    }
    
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack() {
                
                VStack {
                    HStack {
                        Text("Summary")
                            .foregroundColor(.white)
                            .font(.system(size: 30, weight: .bold, design: .monospaced))
                            .padding(.top, 26)
                        
                    }
                    
                    Spacer()
                    
                    
                }
                
                
                TherapyTypeView(therapyType: $therapyType)
                
                DurationView(durationHours: $durationHours, durationMinutes: $durationMinutes, durationSeconds: $durationSeconds)
                
                TemperatureView(temperature: $temperature)
                
                BodyWeightView(bodyWeight: $bodyWeight) // Adding Body Weight to Session
                
                
                HydrationSuggestionView(totalDurationInSeconds: totalDurationInSeconds, temperature: temperature, bodyWeight: bodyWeight)
                HeartRateView(label: "Average HR", heartRate: Int(averageHeartRate))
                HeartRateView(label: "Min HR", heartRate: Int(minHeartRate))
                HeartRateView(label: "Max HR", heartRate: Int(maxHeartRate))
                
                VStack {
                    Spacer()
                    HStack {
                        
                        Spacer()
                        
                        Button(action: discardSession) {
                            Text("Discard")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                        }
                        .padding([.leading, .bottom, .trailing])
                        
                        Button(action: logSession) {
                            Text("Log Session")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                        }
                        .padding([.leading, .bottom, .trailing])
                    }
                }
                
            }
            .padding(.horizontal)
            .padding(.bottom, 26)
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        newSession.date = dateFormatter.string(from: Date())
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
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func discardSession() {
        presentationMode.wrappedValue.dismiss()
    }
    
    struct HeartRateView: View {
        var label: String
        var heartRate: Int
        
        var body: some View {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(label): \(heartRate != 0 && heartRate != 1000 ? "\(heartRate) bpm" : "No Data Available")")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
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
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
                Button(action: { showDurationPicker.toggle() }) {
                    Text("Edit")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, design: .monospaced))
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
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    //Adding Body Weight output to Session Summary Screen
    struct BodyWeightView: View {
        @State var showWeightPicker = false
        @Binding var bodyWeight: Double
        
        var body: some View {
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(.orange)
                Text("Body Weight: \(Int(bodyWeight)) lbs")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
                Button(action: { showWeightPicker.toggle() }) {
                    Text("Edit")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, design: .monospaced))
                        .bold()
                }
                .sheet(isPresented: $showWeightPicker) {
                    VStack {
                        Text("Choose Weight")
                            .font(.title)
                        Picker("Weight", selection: $bodyWeight) {
                            ForEach(50...300, id: \.self) { weight in
                                Text("\(weight) lbs")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 150, height: 150)
                        .clipped()
                        Button("Done", action: { showWeightPicker.toggle() })
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    
    
    struct TemperatureView: View {
        @State var showTemperaturePicker = false
        @Binding var temperature: Int
        
        var body: some View {
            HStack {
                Image(systemName: "thermometer")
                    .foregroundColor(.orange)
                Text("Temperature: \(temperature)°F")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
                Button(action: { showTemperaturePicker.toggle() }) {
                    Text("Edit")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, design: .monospaced))
                        .bold()
                }
                .sheet(isPresented: $showTemperaturePicker) {
                    VStack {
                        Text("Choose Temperature")
                            .font(.title)
                        Picker("Temperature", selection: $temperature) {
                            ForEach(32...212, id: \.self) { temp in
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
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    struct TherapyTypeView: View {
        @Binding var therapyType: TherapyType
        
        var body: some View {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.white)
                Text("Therapy Type: ")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                
                Spacer()
                
                Picker(selection: $therapyType, label: HStack {
                    Text("Therapy Type")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, design: .monospaced))
                        .bold()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.orange)
                }) {
                    ForEach(TherapyType.allCases) { therapyType in
                        Text(therapyType.rawValue)
                            .tag(therapyType)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.trailing)
                .accentColor(.orange)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
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
            let durationInHours = totalDurationInSeconds / 3600.0
            let temperatureAdjustment = Double(max(temperature - 70, 0)) / 10.0 * 0.10
            let waterLossPerHour = 0.5 + temperatureAdjustment
            return (durationInHours * bodyWeight / 2.2046) * waterLossPerHour
        }
        
        var body: some View {
            let formattedWaterLoss = calculateWaterLoss()
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                Text("H20: \(formattedWaterLoss, specifier: "%.2f") liters")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
}

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
    }
    
    private var totalDurationInSeconds: TimeInterval {
        return TimeInterval((durationHours * 3600) + (durationMinutes * 60) + durationSeconds)
    }
    
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack() {
                
                VStack {
                    HStack {
                        Text("Summary")
                            .foregroundColor(.white)
                            .font(.system(size: 30, weight: .bold, design: .monospaced))
                            .padding(.top, 26)
                        
                    }
                    
                    Spacer()
                    
                    
                }
                
                
                TherapyTypeView(therapyType: $therapyType)
                
                DurationView(durationHours: $durationHours, durationMinutes: $durationMinutes, durationSeconds: $durationSeconds)
                
                TemperatureView(temperature: $temperature)
                
                BodyWeightView(bodyWeight: $bodyWeight) // Adding Body Weight to Session
                
                
                HydrationSuggestionView(totalDurationInSeconds: totalDurationInSeconds, temperature: temperature, bodyWeight: bodyWeight)
                HeartRateView(label: "Average HR", heartRate: Int(averageHeartRate))
                HeartRateView(label: "Min HR", heartRate: Int(minHeartRate))
                HeartRateView(label: "Max HR", heartRate: Int(maxHeartRate))
                
                VStack {
                    Spacer()
                    HStack {
                        
                        Spacer()
                        
                        Button(action: discardSession) {
                            Text("Discard")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                        }
                        .padding([.leading, .bottom, .trailing])
                        
                        Button(action: logSession) {
                            Text("Log Session")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                        }
                        .padding([.leading, .bottom, .trailing])
                    }
                }
                
            }
            .padding(.horizontal)
            .padding(.bottom, 26)
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        newSession.date = dateFormatter.string(from: Date())
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
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func discardSession() {
        presentationMode.wrappedValue.dismiss()
    }
    
    struct HeartRateView: View {
        var label: String
        var heartRate: Int
        
        var body: some View {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(label): \(heartRate != 0 && heartRate != 1000 ? "\(heartRate) bpm" : "No Data Available")")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
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
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
                Button(action: { showDurationPicker.toggle() }) {
                    Text("Edit")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, design: .monospaced))
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
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    //Adding Body Weight output to Session Summary Screen
    struct BodyWeightView: View {
        @State var showWeightPicker = false
        @Binding var bodyWeight: Double
        
        var body: some View {
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(.orange)
                Text("Body Weight: \(Int(bodyWeight)) lbs")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
                Button(action: { showWeightPicker.toggle() }) {
                    Text("Edit")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, design: .monospaced))
                        .bold()
                }
                .sheet(isPresented: $showWeightPicker) {
                    VStack {
                        Text("Choose Weight")
                            .font(.title)
                        Picker("Weight", selection: $bodyWeight) {
                            ForEach(50...300, id: \.self) { weight in
                                Text("\(weight) lbs")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 150, height: 150)
                        .clipped()
                        Button("Done", action: { showWeightPicker.toggle() })
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    
    
    struct TemperatureView: View {
        @State var showTemperaturePicker = false
        @Binding var temperature: Int
        
        var body: some View {
            HStack {
                Image(systemName: "thermometer")
                    .foregroundColor(.orange)
                Text("Temperature: \(temperature)°F")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
                Button(action: { showTemperaturePicker.toggle() }) {
                    Text("Edit")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, design: .monospaced))
                        .bold()
                }
                .sheet(isPresented: $showTemperaturePicker) {
                    VStack {
                        Text("Choose Temperature")
                            .font(.title)
                        Picker("Temperature", selection: $temperature) {
                            ForEach(32...212, id: \.self) { temp in
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
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    struct TherapyTypeView: View {
        @Binding var therapyType: TherapyType
        
        var body: some View {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.white)
                Text("Therapy Type: ")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                
                Spacer()
                
                Picker(selection: $therapyType, label: HStack {
                    Text("Therapy Type")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, design: .monospaced))
                        .bold()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.orange)
                }) {
                    ForEach(TherapyType.allCases) { therapyType in
                        Text(therapyType.rawValue)
                            .tag(therapyType)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.trailing)
                .accentColor(.orange)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
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
            let durationInHours = totalDurationInSeconds / 3600.0
            let temperatureAdjustment = Double(max(temperature - 70, 0)) / 10.0 * 0.10
            let waterLossPerHour = 0.5 + temperatureAdjustment
            return (durationInHours * bodyWeight / 2.2046) * waterLossPerHour
        }
        
        var body: some View {
            let formattedWaterLoss = calculateWaterLoss()
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                Text("H20: \(formattedWaterLoss, specifier: "%.2f") liters")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
}

