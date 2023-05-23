import SwiftUI
import CoreData

struct SessionSummary: View {
    @State private var duration: TimeInterval
    @State private var averageHeartRate: Double
    @State private var averageSpo2: Double
    @State private var averageRespirationRate: Double

    @Binding private var therapyType: TherapyType
    @State private var durationHours: Int = 0
    @State private var durationMinutes: Int = 0
    @State private var durationSeconds: Int = 0
    @State private var temperature: Int = 70
    @State private var bodyWeight: Double = 0
    @State private var showDurationPicker = false
    @State private var showTemperaturePicker = false
    @Environment(\.presentationMode) var presentationMode

    @Environment(\.managedObjectContext) private var viewContext

    init(duration: TimeInterval, therapyType: Binding<TherapyType>, averageHeartRate: Double, averageSpo2: Double, averageRespirationRate: Double) {
        self._duration = State(initialValue: duration)
        self._therapyType = therapyType
        self._averageHeartRate = State(initialValue: averageHeartRate)
        self._averageSpo2 = State(initialValue: averageSpo2)
        self._averageRespirationRate = State(initialValue: averageRespirationRate)

        let (hours, minutes, seconds) = secondsToHoursMinutesSeconds(seconds: Int(duration))
        self._durationHours = State(initialValue: hours)
        self._durationMinutes = State(initialValue: minutes)
        self._durationSeconds = State(initialValue: seconds)
    }

    private var totalDurationInSeconds: TimeInterval {
        return TimeInterval((durationHours * 3600) + (durationMinutes * 60) + durationSeconds)
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Summary")
                    .foregroundColor(.white)
                    .font(.system(size: 30, design: .monospaced))
                    .padding()
                Spacer()
            }

            HStack {
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
                .background(RoundedRectangle(cornerRadius: 8).fill(LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom)))
                .padding(.trailing)
                .accentColor(.orange)
            }
            .padding()

            // Duration
            HStack {
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

            // Heart Rate
            HStack {
                Text("Average Heart Rate: \(Int(averageHeartRate)) bpm")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
            }
            .padding()

            // SpO2
            HStack {
                Text("Average SpO2: \(Int(averageSpo2))%")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
            }
            .padding()

            // Respiration Rate
            HStack {
                Text("Average Respiration Rate: \(Int(averageRespirationRate)) breaths/min")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
            }
            .padding()

            HStack {
                Button(action: discardSession) {
                    Text("Discard")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.system(size: 16, design: .monospaced))
                }
                .padding([.leading, .bottom, .trailing])

                Button(action: logSession) {
                    Text("Log Session")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.system(size: 16, design: .monospaced))
                }
                .padding([.leading, .bottom, .trailing])
            }

            Spacer()
        }
        .padding(.horizontal)
        .background(LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom).edgesIgnoringSafeArea(.all))
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
}
