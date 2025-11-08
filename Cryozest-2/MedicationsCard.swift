//
//  MedicationsCard.swift
//  Cryozest-2
//
//  Daily medications tracking card
//

import SwiftUI
import CoreData

struct MedicationsCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date

    @FetchRequest(
        entity: Medication.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Medication.createdDate, ascending: true)]
    )
    private var allMedications: FetchedResults<Medication>

    @State private var showAddMedication = false
    @State private var takenStates: [UUID: Bool] = [:]

    private var activeMedications: [Medication] {
        allMedications.filter { $0.isActive }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)

                    Text("Medications")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if isToday {
                    Button(action: { showAddMedication = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Add")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.15))
                        )
                    }
                }
            }

            if activeMedications.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "pills")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.white.opacity(0.3))

                    Text("No medications added")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))

                    if isToday {
                        Button(action: { showAddMedication = true }) {
                            Text("Add your first medication")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.green)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.2))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Medications list
                VStack(spacing: 10) {
                    ForEach(activeMedications, id: \.id) { medication in
                        MedicationRow(
                            medication: medication,
                            selectedDate: selectedDate,
                            isToday: isToday,
                            isTaken: takenStates[medication.id!] ?? false,
                            onToggle: {
                                toggleMedication(medication)
                            }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showAddMedication) {
            AddMedicationSheet()
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            loadTakenStates()
        }
        .onChange(of: selectedDate) { _ in
            loadTakenStates()
        }
        .onChange(of: allMedications.count) { _ in
            loadTakenStates()
        }
    }

    private func loadTakenStates() {
        var states: [UUID: Bool] = [:]
        for medication in activeMedications {
            if let medId = medication.id {
                states[medId] = MedicationIntake.wasTaken(
                    medicationId: medId,
                    on: selectedDate,
                    context: viewContext
                )
            }
        }
        takenStates = states
    }

    private func toggleMedication(_ medication: Medication) {
        guard let medId = medication.id else { return }

        let wasTaken = takenStates[medId] ?? false

        if wasTaken {
            // Undo - mark as not taken
            MedicationIntake.markAsNotTaken(
                medicationId: medId,
                on: selectedDate,
                context: viewContext
            )
            takenStates[medId] = false
        } else {
            // Mark as taken
            MedicationIntake.markAsTaken(
                medication: medication,
                on: selectedDate,
                context: viewContext
            )
            takenStates[medId] = true

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

struct MedicationRow: View {
    let medication: Medication
    let selectedDate: Date
    let isToday: Bool
    let isTaken: Bool
    let onToggle: () -> Void

    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingOptions = false

    private var frequencyDisplay: String {
        medication.frequency ?? "Daily"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                if isToday {
                    onToggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isTaken ? Color.green.opacity(0.25) : Color.white.opacity(0.08))
                        .frame(width: 40, height: 40)

                    Circle()
                        .stroke(isTaken ? Color.green : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 40, height: 40)

                    if isTaken {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            .disabled(!isToday)

            // Medication info
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name ?? "Medication")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .strikethrough(isTaken, color: .white.opacity(0.5))

                Text(frequencyDisplay)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Options button
            if isToday {
                Button(action: { showingOptions = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.05))
                        )
                }
            }
        }
        .padding(.vertical, 6)
        .confirmationDialog("Medication Options", isPresented: $showingOptions, titleVisibility: .visible) {
            Button("Delete Medication", role: .destructive) {
                medication.permanentlyDelete(context: viewContext)
            }
        }
    }
}
