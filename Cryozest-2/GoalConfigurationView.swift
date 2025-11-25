//
//  GoalConfigurationView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  UI for setting therapy goals
//

import SwiftUI
import CoreData

struct GoalConfigurationView: View {
    let selectedTherapyTypes: [TherapyType]
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var goalManager = GoalManager.shared

    @State private var goalSettings: [String: TherapyGoals] = [:]

    init(selectedTherapyTypes: [TherapyType]) {
        self.selectedTherapyTypes = selectedTherapyTypes
        let manager = GoalManager.shared
        var settings: [String: TherapyGoals] = [:]
        for type in selectedTherapyTypes {
            settings[type.rawValue] = TherapyGoals(
                weekly: manager.getWeeklyGoal(for: type),
                monthly: manager.getMonthlyGoal(for: type),
                yearly: manager.getYearlyGoal(for: type)
            )
        }
        _goalSettings = State(initialValue: settings)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Deep navy background
                Color(red: 0.06, green: 0.10, blue: 0.18)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.cyan)

                        Text("Set Your Goals")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("Configure goals for each habit")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    // Scrollable list of therapy types
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(selectedTherapyTypes, id: \.self) { therapyType in
                                TherapyGoalSection(
                                    therapyType: therapyType,
                                    goals: binding(for: therapyType)
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }

                    // Save button (fixed at bottom)
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.white.opacity(0.2))

                        Button(action: saveGoals) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))

                                Text("Save All Goals")
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
                                                Color.cyan,
                                                Color.cyan.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(
                            Color(red: 0.1, green: 0.2, blue: 0.35).opacity(0.95)
                        )
                    }
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

    private func binding(for therapyType: TherapyType) -> Binding<TherapyGoals> {
        Binding(
            get: { goalSettings[therapyType.rawValue] ?? TherapyGoals(weekly: 3, monthly: 12, yearly: 150) },
            set: { goalSettings[therapyType.rawValue] = $0 }
        )
    }

    private func saveGoals() {
        for therapyType in selectedTherapyTypes {
            if let goals = goalSettings[therapyType.rawValue] {
                goalManager.setWeeklyGoal(goals.weekly, for: therapyType)
                goalManager.setMonthlyGoal(goals.monthly, for: therapyType)
                goalManager.setYearlyGoal(goals.yearly, for: therapyType)
            }
        }
        dismiss()
    }
}

struct TherapyGoals {
    var weekly: Int
    var monthly: Int
    var yearly: Int
}

struct TherapyGoalSection: View {
    let therapyType: TherapyType
    @Binding var goals: TherapyGoals

    var body: some View {
        VStack(spacing: 12) {
            // Therapy header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(therapyType.color.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: therapyType.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(therapyType.color)
                }

                Text(therapyType.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
            }

            // Goal inputs
            VStack(spacing: 12) {
                CompactGoalInput(
                    icon: "calendar.badge.clock",
                    title: "Weekly",
                    value: $goals.weekly,
                    color: therapyType.color,
                    range: 1...7
                )

                CompactGoalInput(
                    icon: "calendar",
                    title: "Monthly",
                    value: $goals.monthly,
                    color: therapyType.color,
                    range: 1...31
                )

                CompactGoalInput(
                    icon: "calendar.badge.plus",
                    title: "Yearly",
                    value: $goals.yearly,
                    color: therapyType.color,
                    range: 1...365
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(therapyType.color.opacity(0.3), lineWidth: 1.5)
                )
        )
    }
}

struct CompactGoalInput: View {
    let icon: String
    let title: String
    @Binding var value: Int
    let color: Color
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 70, alignment: .leading)

            Spacer()

            // Compact stepper
            HStack(spacing: 12) {
                Button(action: { if value > range.lowerBound { value -= 1 } }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value > range.lowerBound ? color : Color.white.opacity(0.3))
                }
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 35)

                Button(action: { if value < range.upperBound { value += 1 } }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value < range.upperBound ? color : Color.white.opacity(0.3))
                }
                .disabled(value >= range.upperBound)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct GoalInputCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var value: Int
    let color: Color
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Stepper
                HStack(spacing: 16) {
                    Button(action: { if value > range.lowerBound { value -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(value > range.lowerBound ? color : Color.white.opacity(0.3))
                    }
                    .disabled(value <= range.lowerBound)

                    Text("\(value)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 40)

                    Button(action: { if value < range.upperBound { value += 1 } }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(value < range.upperBound ? color : Color.white.opacity(0.3))
                    }
                    .disabled(value >= range.upperBound)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
