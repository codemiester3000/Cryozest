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
    @State private var isCollapsed = false
    @State private var lastToggledMedication: Medication?
    @State private var showCompletionAnimation = false

    private var activeMedications: [Medication] {
        allMedications.filter { $0.isActive }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var allMedicationsTaken: Bool {
        !activeMedications.isEmpty && activeMedications.allSatisfy { medication in
            guard let medId = medication.id else { return false }
            return takenStates[medId] ?? false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if allMedicationsTaken && isCollapsed && isToday {
                // Collapsed completion state
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.25))
                            .frame(width: 48, height: 48)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.green)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("All medications taken")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)

                        Text("\(activeMedications.count) of \(activeMedications.count) completed")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    // Undo button
                    if lastToggledMedication != nil {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                undoLastToggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Undo")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            } else {
                // Expanded state - Header
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
            }  // Close expanded state else
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
        .overlay(
            // Completion animation overlay
            Group {
                if showCompletionAnimation {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
            }
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
            isCollapsed = false  // Expand when unchecking
        } else {
            // Mark as taken
            MedicationIntake.markAsTaken(
                medication: medication,
                on: selectedDate,
                context: viewContext
            )
            takenStates[medId] = true
            lastToggledMedication = medication

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            // Check if all medications are now taken
            if allMedicationsTaken {
                // Trigger completion animation
                showCompletionAnimation = true

                // Heavy haptic for completion
                let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
                heavyGenerator.impactOccurred()

                // Collapse after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isCollapsed = true
                    }
                }

                // Hide animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showCompletionAnimation = false
                }
            }
        }
    }

    private func undoLastToggle() {
        guard let medication = lastToggledMedication,
              let medId = medication.id else { return }

        // Mark as not taken
        MedicationIntake.markAsNotTaken(
            medicationId: medId,
            on: selectedDate,
            context: viewContext
        )
        takenStates[medId] = false
        isCollapsed = false
        lastToggledMedication = nil

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
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
            Button(action: onToggle) {
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

// MARK: - Confetti Animation

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
    }

    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.green, .cyan, .yellow, .orange, .purple]
        confettiPieces = (0..<50).map { index in
            ConfettiPiece(
                id: index,
                color: colors.randomElement()!,
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 4...10)
            )
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let size: CGFloat
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(x: piece.x + xOffset, y: piece.y + yOffset)
            .onAppear {
                // Animate falling
                withAnimation(
                    Animation.easeIn(duration: Double.random(in: 1.5...2.5))
                        .delay(Double.random(in: 0...0.3))
                ) {
                    yOffset = 400
                    xOffset = CGFloat.random(in: -50...50)
                    rotation = Double.random(in: 360...720)
                    opacity = 0
                }
            }
    }
}
