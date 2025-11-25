//
//  OnboardingHabitSelectionView.swift
//  Cryozest-2
//
//  Screen 2: Habit Selection - Choose wellness activities to track
//

import SwiftUI
import CoreData

struct OnboardingHabitSelectionView: View {
    @Binding var selectedHabits: [TherapyType]
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var selectedCategory: Category = .category0
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.managedObjectContext) var managedObjectContext

    var body: some View {
        ZStack {
            // Deep navy background
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Choose Your Habits")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Select at least 2 activities you want to track")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .padding(.bottom, 24)
                .opacity(showContent ? 1 : 0)

                // Category pills
                CategoryPillsView(selectedCategory: $selectedCategory)
                    .frame(height: 60)
                    .padding(.bottom, 16)

                // Scrollable habit list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(TherapyType.therapies(forCategory: selectedCategory), id: \.self) { therapyType in
                            let isWorkout = selectedCategory == .category0
                            HabitCard(
                                therapyType: therapyType,
                                isSelected: selectedHabits.contains(therapyType),
                                isWorkout: isWorkout,
                                onTap: {
                                    if selectedHabits.contains(therapyType) {
                                        selectedHabits.removeAll(where: { $0 == therapyType })
                                    } else if selectedHabits.count < 6 {
                                        selectedHabits.append(therapyType)
                                    } else {
                                        alertMessage = "You can select up to 6 habits"
                                        showAlert = true
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 140)
                }

                Spacer()

                // Continue button
                Button(action: {
                    if selectedHabits.count < 2 {
                        alertMessage = "Please select at least 2 habits to continue"
                        showAlert = true
                    } else {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onContinue()
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(selectedHabits.count >= 2 ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: selectedHabits.count >= 2 ? [
                                Color.green,
                                Color.green.opacity(0.8)
                            ] : [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: selectedHabits.count >= 2 ? Color.green.opacity(0.4) : .clear, radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 120)
                .opacity(showContent ? 1 : 0)
            }
        }
        .alert("Note", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

struct HabitCard: View {
    let therapyType: TherapyType
    let isSelected: Bool
    let isWorkout: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(therapyType.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: therapyType.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(therapyType.color)
                }

                // Name and badge
                VStack(alignment: .leading, spacing: 4) {
                    Text(therapyType.displayName(NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    if isWorkout {
                        HStack(spacing: 4) {
                            Image(systemName: "applewatch")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Auto-Sync")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                    }
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? therapyType.color : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isSelected {
                        Circle()
                            .fill(therapyType.color)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? therapyType.color.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OnboardingHabitSelectionView(
        selectedHabits: .constant([]),
        onContinue: {}
    )
}
