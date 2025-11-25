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
                // Icon
                Image(systemName: therapy.icon)
                    .font(.system(size: isSelected ? 20 : 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : therapy.color.opacity(0.6))
                    .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                    .background(
                        ZStack {
                            // Outer glow ring for selected state
                            if isSelected {
                                Circle()
                                    .fill(therapy.color.opacity(0.3))
                                    .frame(width: 48, height: 48)
                                    .blur(radius: 4)
                            }

                            Circle()
                                .fill(
                                    isSelected
                                        ? LinearGradient(
                                            gradient: Gradient(colors: [
                                                therapy.color,
                                                therapy.color.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            gradient: Gradient(colors: [
                                                therapy.color.opacity(0.12),
                                                therapy.color.opacity(0.08)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                        }
                    )

                // Name and badge
                VStack(alignment: .leading, spacing: 4) {
                    Text(therapy.displayName(managedObjectContext))
                        .font(.system(size: isSelected ? 17 : 14, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.5))

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
                                .fill(Color.green.opacity(0.15))
                        )
                    }
                }
            }
            .padding(.horizontal, isSelected ? 20 : 14)
            .padding(.vertical, isSelected ? 14 : 10)
            .background(
                RoundedRectangle(cornerRadius: isSelected ? 22 : 16)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                gradient: Gradient(colors: [
                                    therapy.color.opacity(0.25),
                                    therapy.color.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.03)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isSelected ? 22 : 16)
                            .stroke(
                                isSelected
                                    ? therapy.color.opacity(0.8)
                                    : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? therapy.color.opacity(0.4) : Color.clear,
                radius: isSelected ? 16 : 0,
                x: 0,
                y: isSelected ? 8 : 0
            )
            .scaleEffect(isSelected ? 1.05 : (isPressed ? 0.95 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
