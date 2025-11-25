//
//  AddMedicationSheet.swift
//  Cryozest-2
//
//  Sheet for adding new medications
//

import SwiftUI
import CoreData

struct AddMedicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var medicationName = ""
    @State private var selectedFrequency = "Once daily"
    @State private var enableReminder = false
    @State private var reminderTime = Date()
    @State private var showingSuggestions = false

    private let frequencies = ["Once daily", "Twice daily", "Three times daily", "As needed"]

    // Common medications for autocomplete (keeping it simple with OTC meds)
    private let commonMedications = [
        "Aspirin", "Ibuprofen", "Acetaminophen", "Vitamin D",
        "Multivitamin", "Fish Oil", "Melatonin", "Probiotic",
        "Iron", "Calcium", "Magnesium", "Zinc",
        "B12", "C Vitamin", "Omega-3", "CoQ10"
    ].sorted()

    private var filteredSuggestions: [String] {
        if medicationName.isEmpty {
            return []
        }
        return commonMedications.filter {
            $0.localizedCaseInsensitiveContains(medicationName)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Deep navy background
                Color(red: 0.06, green: 0.10, blue: 0.18)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "pills.fill")
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundColor(.green)
                            }

                            Text("Add Medication")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Track your medication adherence")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 20)

                        // Medication Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Medication Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))

                            TextField("Enter medication name", text: $medicationName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .autocapitalization(.words)
                                .onChange(of: medicationName) { _ in
                                    showingSuggestions = !filteredSuggestions.isEmpty
                                }

                            // Suggestions
                            if showingSuggestions && !filteredSuggestions.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(filteredSuggestions.prefix(5), id: \.self) { suggestion in
                                        Button(action: {
                                            medicationName = suggestion
                                            showingSuggestions = false
                                        }) {
                                            HStack {
                                                Image(systemName: "pills")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.green.opacity(0.7))

                                                Text(suggestion)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(.white)

                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                        }

                                        if suggestion != filteredSuggestions.prefix(5).last {
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        // Frequency
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Frequency")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))

                            VStack(spacing: 8) {
                                ForEach(frequencies, id: \.self) { frequency in
                                    Button(action: {
                                        selectedFrequency = frequency
                                    }) {
                                        HStack {
                                            Text(frequency)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.white)

                                            Spacer()

                                            if selectedFrequency == frequency {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.green)
                                            } else {
                                                Circle()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                                    .frame(width: 20, height: 20)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedFrequency == frequency ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(
                                                            selectedFrequency == frequency ? Color.green.opacity(0.4) : Color.white.opacity(0.15),
                                                            lineWidth: 1
                                                        )
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Reminder toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $enableReminder) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)

                                    Text("Daily Reminder")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .tint(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )

                            if enableReminder {
                                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .tint(.green)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        .padding(.horizontal, 24)

                        // Disclaimer
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))

                            Text("This is not medical advice. Consult your healthcare provider about your medications.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }

                // Save button (fixed at bottom)
                VStack {
                    Spacer()

                    Button(action: saveMedication) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))

                            Text("Add Medication")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            medicationName.isEmpty ? Color.gray : Color.green,
                                            medicationName.isEmpty ? Color.gray.opacity(0.8) : Color.green.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .disabled(medicationName.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color(red: 0.1, green: 0.2, blue: 0.35).opacity(0.95)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    private func saveMedication() {
        guard !medicationName.isEmpty else { return }

        _ = Medication.create(
            name: medicationName,
            frequency: selectedFrequency,
            reminderTime: enableReminder ? reminderTime : nil,
            context: viewContext
        )

        dismiss()
    }
}
