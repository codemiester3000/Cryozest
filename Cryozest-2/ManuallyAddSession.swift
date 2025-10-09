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

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    Text("Add Session")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    // Invisible placeholder for symmetry
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 16) {
                        // Therapy Type Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Habit Type")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))

                            Menu {
                                ForEach(TherapyType.allCases, id: \.self) { type in
                                    Button(action: { therapyType = type }) {
                                        HStack {
                                            Text(type.displayName(viewContext))
                                            if therapyType == type {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(therapyType.displayName(viewContext))
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.cyan)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                )
                            }
                        }

                        // Date Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Session Date")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))

                            DatePicker("", selection: $sessionDate, displayedComponents: .date)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                )
                        }

                        // Duration Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))

                            HStack(spacing: 12) {
                                // Hours
                                VStack {
                                    Stepper("", value: $durationHours, in: 0...23)
                                        .labelsHidden()
                                    Text("\(durationHours) hr")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                )

                                // Minutes
                                VStack {
                                    Stepper("", value: $durationMinutes, in: 0...59)
                                        .labelsHidden()
                                    Text("\(durationMinutes) min")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                )
                            }
                        }

                        // Heart Rate Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Average Heart Rate")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))

                            HStack {
                                Stepper("", value: $averageHeartRate, in: 40...200)
                                    .labelsHidden()
                                Spacer()
                                Text("\(averageHeartRate) bpm")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.cyan)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                        }

                        // Save Button
                        Button(action: {
                            if requiresSafetyWarning(therapyType) {
                                showSafetyWarning = true
                                pendingSave = true
                            } else {
                                saveSession()
                            }
                        }) {
                            Text("Save Session")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            therapyType.color,
                                            therapyType.color.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: therapyType.color.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
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
