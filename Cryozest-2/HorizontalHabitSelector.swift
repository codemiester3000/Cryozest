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
            Text("Current Habit")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .padding(.leading, 24)

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
                    .onChange(of: therapyTypeSelection.selectedTherapyType) { newValue in
                        withAnimation {
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

    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(spacing: 10) {
                // Icon
                Image(systemName: therapy.icon)
                    .font(.system(size: isSelected ? 18 : 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : therapy.color)
                    .frame(width: isSelected ? 36 : 32, height: isSelected ? 36 : 32)
                    .background(
                        Circle()
                            .fill(
                                isSelected
                                    ? LinearGradient(
                                        gradient: Gradient(colors: [
                                            therapy.color.opacity(0.8),
                                            therapy.color.opacity(0.6)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        gradient: Gradient(colors: [
                                            therapy.color.opacity(0.15),
                                            therapy.color.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                    )

                // Name
                Text(therapy.displayName(managedObjectContext))
                    .font(.system(size: isSelected ? 16 : 15, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .padding(.horizontal, isSelected ? 20 : 16)
            .padding(.vertical, isSelected ? 14 : 12)
            .background(
                RoundedRectangle(cornerRadius: isSelected ? 20 : 18)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.12)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.04)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isSelected ? 20 : 18)
                            .stroke(
                                isSelected
                                    ? therapy.color.opacity(0.6)
                                    : Color.white.opacity(0.15),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? therapy.color.opacity(0.3) : Color.black.opacity(0.1),
                radius: isSelected ? 12 : 4,
                x: 0,
                y: isSelected ? 6 : 2
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
