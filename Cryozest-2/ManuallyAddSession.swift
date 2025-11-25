import SwiftUI
import CoreData

struct ManuallyAddSession: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    // Simplified properties - just habit type and date
    @State private var therapyType: TherapyType = .running
    @State private var sessionDate: Date = Date()

    // Safety warning
    @State private var showSafetyWarning: Bool = false
    @State private var pendingSave: Bool = false

    var body: some View {
        ZStack {
            backgroundGradients
            contentView
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

    private var backgroundGradients: some View {
        Color(red: 0.06, green: 0.10, blue: 0.18)
            .ignoresSafeArea()
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            headerView
            ScrollView {
                VStack(spacing: 24) {
                    habitTypeSection
                    dateSection
                    saveButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private var headerView: some View {
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

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .opacity(0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }

    private var habitTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Which Habit?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

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
                habitTypeMenuLabel
            }
        }
    }

    private var habitTypeMenuLabel: some View {
        HStack {
            Image(systemName: therapyType.icon)
                .font(.system(size: 20))
                .foregroundColor(therapyType.color)
            Text(therapyType.displayName(viewContext))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.cyan)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(therapyType.color.opacity(0.3), lineWidth: 2)
                )
        )
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What Day?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            DatePicker("", selection: $sessionDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .colorScheme(.dark)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
        }
    }

    private var saveButton: some View {
        Button(action: {
            if requiresSafetyWarning(therapyType) {
                showSafetyWarning = true
                pendingSave = true
            } else {
                saveSession()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text("Mark as Complete")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
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
            .cornerRadius(16)
            .shadow(color: therapyType.color.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .padding(.top, 16)
    }

    func requiresSafetyWarning(_ type: TherapyType) -> Bool {
        // Safety warnings disabled for App Store compliance
        return false
    }

    private func saveSession() {
        let newSession = TherapySessionEntity(context: viewContext)
        newSession.id = UUID()
        newSession.date = sessionDate
        newSession.therapyType = therapyType.rawValue

        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving session: \(error.localizedDescription)")
        }
    }
}
