//
//  OnboardingFlowView.swift
//  Cryozest-2
//
//  Simple 3-step onboarding: Intro → Habits → Health
//

import SwiftUI
import CoreData

struct OnboardingFlowView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var appState: AppState
    @State private var step = 0
    @State private var selectedHabits: [TherapyType] = []
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                progressBar
                    .padding(.top, 60)
                    .padding(.horizontal, 24)

                // Content
                TabView(selection: $step) {
                    IntroStep(onContinue: { step = 1 })
                        .tag(0)

                    HabitsStep(
                        selectedHabits: $selectedHabits,
                        onContinue: {
                            saveHabits()
                            step = 2
                        }
                    )
                    .tag(1)

                    HealthStep(onComplete: {
                        appState.hasLaunchedBefore = true
                        appState.hasSelectedTherapyTypes = true
                        onComplete()
                    })
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Color.cyan : Color.white.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }

    private func saveHabits() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SelectedTherapy.fetchRequest()
        if let results = try? managedObjectContext.fetch(fetchRequest) as? [NSManagedObject] {
            results.forEach { managedObjectContext.delete($0) }
        }

        for habit in selectedHabits {
            let therapy = SelectedTherapy(context: managedObjectContext)
            therapy.therapyType = habit.rawValue
        }

        try? managedObjectContext.save()
    }
}

// MARK: - Step 1: Intro
struct IntroStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.cyan)
            }
            .padding(.bottom, 40)

            // Text
            VStack(spacing: 16) {
                Text("Find what works for you")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Track your habits and see how they\nactually impact your health data.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Button
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.cyan)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 2: Habits
struct HabitsStep: View {
    @Binding var selectedHabits: [TherapyType]
    let onContinue: () -> Void

    @State private var category: Category = .category0
    @Environment(\.managedObjectContext) var managedObjectContext

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var canContinue: Bool {
        selectedHabits.count >= 2
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Select your habits")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Choose 2-6 habits to track")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Category.allCases, id: \.self) { cat in
                        Button(action: { category = cat }) {
                            HStack(spacing: 6) {
                                if cat == .category0 {
                                    Image(systemName: "applewatch")
                                        .font(.system(size: 10))
                                        .foregroundColor(.green)
                                }
                                Text(cat.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(category == cat ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(category == cat ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(category == cat ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }

            // Grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(TherapyType.therapies(forCategory: category), id: \.self) { type in
                        HabitTileOnboarding(
                            type: type,
                            name: type.displayName(managedObjectContext),
                            isSelected: selectedHabits.contains(type),
                            syncs: category == .category0
                        ) {
                            toggleHabit(type)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }

            Spacer(minLength: 0)

            // Bottom
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.10, blue: 0.18).opacity(0),
                        Color(red: 0.06, green: 0.10, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)

                Button(action: onContinue) {
                    Text(canContinue ? "Continue" : "Select at least 2")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(canContinue ? .black : .white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(canContinue ? Color.cyan : Color.white.opacity(0.1))
                        )
                }
                .disabled(!canContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .background(Color(red: 0.06, green: 0.10, blue: 0.18))
            }
        }
    }

    private func toggleHabit(_ type: TherapyType) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if selectedHabits.contains(type) {
            selectedHabits.removeAll { $0 == type }
        } else if selectedHabits.count < 6 {
            selectedHabits.append(type)
        }
    }
}

struct HabitTileOnboarding: View {
    let type: TherapyType
    let name: String
    let isSelected: Bool
    let syncs: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(type.color)
                }

                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if syncs {
                    HStack(spacing: 3) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 8))
                        Text("syncs")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.green.opacity(0.8))
                } else {
                    Text(" ").font(.system(size: 10))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.cyan : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.cyan)
                                .padding(8)
                        }
                    }
                    Spacer()
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Step 3: Health
struct HealthStep: View {
    let onComplete: () -> Void

    @State private var isConnecting = false
    @State private var isConnected = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(isConnected ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: isConnected ? "checkmark" : "heart.fill")
                    .font(.system(size: isConnected ? 48 : 56, weight: isConnected ? .bold : .regular))
                    .foregroundColor(isConnected ? .green : .red)
            }
            .padding(.bottom, 40)

            // Text
            VStack(spacing: 16) {
                Text(isConnected ? "You're all set" : "Connect Apple Health")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(isConnected
                     ? "We'll analyze your data and\nshow you what's working."
                     : "We need access to your health data\nto find patterns and correlations.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Button
            Button(action: {
                if isConnected {
                    onComplete()
                } else {
                    connect()
                }
            }) {
                HStack(spacing: 8) {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    }
                    Text(isConnected ? "Start Using Cryozest" : (isConnecting ? "Connecting..." : "Connect Health"))
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(isConnected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isConnected ? Color.cyan : Color.red)
                .cornerRadius(14)
            }
            .disabled(isConnecting)
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }

    private func connect() {
        isConnecting = true
        HealthKitManager.shared.requestAuthorization { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isConnecting = false
                withAnimation(.easeOut(duration: 0.2)) {
                    isConnected = true
                }
            }
        }
    }
}

#Preview {
    OnboardingFlowView(onComplete: {})
}
