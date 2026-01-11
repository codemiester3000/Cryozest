//
//  HorizontalHabitSelector.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/8/25.
//

import SwiftUI
import CoreData

struct HorizontalHabitSelector: View {
    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    let selectedTherapyTypes: FetchedResults<SelectedTherapy>
    @Environment(\.managedObjectContext) var managedObjectContext

    init(therapyTypeSelection: TherapyTypeSelection, selectedTherapyTypes: FetchedResults<SelectedTherapy>) {
        self.therapyTypeSelection = therapyTypeSelection
        self.selectedTherapyTypes = selectedTherapyTypes
    }

    private var availableTherapies: [TherapyType] {
        selectedTherapyTypes.compactMap { selectedTherapy in
            if let typeString = selectedTherapy.therapyType {
                return TherapyType(rawValue: typeString)
            }
            return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
     

            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 12) {
                        ForEach(availableTherapies, id: \.self) { therapy in
                            HabitPill(
                                therapy: therapy,
                                isSelected: therapyTypeSelection.selectedTherapyType == therapy,
                                managedObjectContext: managedObjectContext
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    therapyTypeSelection.selectedTherapyType = therapy
                                }

                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                            .id(therapy)
                        }
                    }
                    .padding(.horizontal, 24)
                    .onAppear {
                        // Scroll to selected habit on initial load
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(therapyTypeSelection.selectedTherapyType, anchor: .center)
                            }
                        }
                    }
                    .onChange(of: therapyTypeSelection.selectedTherapyType) { newValue in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

struct HabitPill: View {
    let therapy: TherapyType
    let isSelected: Bool
    let managedObjectContext: NSManagedObjectContext
    let onTap: () -> Void

    @State private var isPressed = false

    // Check if this is a workout type (auto-syncs with Apple Watch)
    private var isWorkout: Bool {
        let workoutTypes = TherapyType.therapies(forCategory: .category0)
        return workoutTypes.contains(therapy)
    }

    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(spacing: 10) {
                // Icon with glow when selected
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(therapy.color.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .blur(radius: 6)
                    }

                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [therapy.color, therapy.color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [therapy.color.opacity(0.2), therapy.color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(isSelected ? 0.4 : 0.15), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )

                    Image(systemName: therapy.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : therapy.color)
                }

                // Name and badge
                VStack(alignment: .leading, spacing: 4) {
                    Text(therapy.displayName(managedObjectContext))
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))

                    // Apple Watch badge for workout types
                    if isWorkout && isSelected {
                        HStack(spacing: 3) {
                            Image(systemName: "applewatch")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)

                            Text("Auto-Sync")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.green.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [therapy.color.opacity(0.25), therapy.color.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )

                    // Glass highlight
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: isSelected
                                    ? [therapy.color.opacity(0.5), therapy.color.opacity(0.2)]
                                    : [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            )
            .shadow(
                color: isSelected ? therapy.color.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
