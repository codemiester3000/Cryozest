//
//  StepGoalConfigView.swift
//  Cryozest-2
//
//  Configuration view for setting daily step goals
//

import SwiftUI

struct StepGoalConfigView: View {
    @ObservedObject var goalManager = StepGoalManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var goalInput: String = ""
    @State private var showError = false

    init() {
        _goalInput = State(initialValue: "\(StepGoalManager.shared.dailyStepGoal)")
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
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

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundColor(.green)
                            .padding(20)
                            .background(
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                            )

                        Text("Daily Step Goal")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("Set your target steps per day")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)

                    // Goal input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Goal (steps)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        TextField("Enter step goal", text: $goalInput)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(showError ? Color.red.opacity(0.5) : Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            )

                        if showError {
                            Text("Please enter a goal between 1,000 and 50,000 steps")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Quick presets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Presets")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(spacing: 12) {
                            PresetButton(value: 5000, goalInput: $goalInput)
                            PresetButton(value: 10000, goalInput: $goalInput)
                            PresetButton(value: 15000, goalInput: $goalInput)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Save button
                    Button(action: saveGoal) {
                        Text("Save Goal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.green)
                            )
                            .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
    }

    private func saveGoal() {
        guard let goal = Int(goalInput), goal >= 1000, goal <= 50000 else {
            showError = true
            return
        }

        showError = false
        goalManager.updateGoal(goal)
        dismiss()
    }
}

struct PresetButton: View {
    let value: Int
    @Binding var goalInput: String

    var body: some View {
        Button(action: {
            goalInput = "\(value)"
        }) {
            VStack(spacing: 4) {
                Text("\(value / 1000)K")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text("steps")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}
