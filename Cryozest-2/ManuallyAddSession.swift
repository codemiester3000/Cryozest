import SwiftUI
import CoreData

struct ManuallyAddSession: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    // Existing properties
    @State private var therapyType: TherapyType = .drySauna
    @State private var temperature: Int = 70
    @State private var durationHours: Int = 1
    @State private var durationMinutes: Int = 0
    @State private var sessionDate: Date = Date()

    // New property for average heart rate
    @State private var averageHeartRate: Int = 70 // Default value

    // Safety warning
    @State private var showSafetyWarning: Bool = false
    @State private var pendingSave: Bool = false

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

            NavigationView {
                Form {
                Picker("Therapy Type", selection: $therapyType) {
                    ForEach(TherapyType.allCases, id: \.self) { type in
                        Text(type.displayName(viewContext)).tag(type)
                    }
                }

                DatePicker("Session Date", selection: $sessionDate, displayedComponents: .date)

                Stepper("Hours: \(durationHours)", value: $durationHours, in: 0...23)
                Stepper("Minutes: \(durationMinutes)", value: $durationMinutes, in: 0...59)

                // Stepper for average heart rate
                Stepper("Average Heart Rate: \(averageHeartRate) bpm", value: $averageHeartRate, in: 40...200) // Adjust range as needed

                Button("Save Session") {
                    if requiresSafetyWarning(therapyType) {
                        showSafetyWarning = true
                        pendingSave = true
                    } else {
                        saveSession()
                    }
                }
                .foregroundColor(.red)
            }
            .navigationBarTitle("Add Habit Entry", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            }
        }
        .fullScreenCover(isPresented: $showSafetyWarning) {
            DeviceSafetyWarningView(
                isPresented: $showSafetyWarning,
                therapyType: therapyType,
                onContinue: {
                    if pendingSave {
                        saveSession()
                        pendingSave = false
                    }
                }
            )
        }
    }

    func requiresSafetyWarning(_ type: TherapyType) -> Bool {
        switch type {
        case .drySauna, .hotYoga, .coldPlunge, .coldShower, .iceBath:
            return true
        default:
            return false
        }
    }

    private func saveSession() {
        let newSession = TherapySessionEntity(context: viewContext)
        newSession.id = UUID()
        newSession.date = sessionDate
        newSession.duration = Double(durationHours * 3600 + durationMinutes * 60)
        newSession.therapyType = therapyType.rawValue
        newSession.temperature = Double(temperature)
        newSession.averageHeartRate = Double(averageHeartRate)

        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving session: \(error.localizedDescription)")
        }
    }
}
