//
//  OnboardingFlowView.swift
//  Cryozest-2
//
//  World-class 5-step onboarding inspired by Duolingo, Calm, Noom, Headspace
//  Flow: Value Demo → Goals → Habits → Health → Promise
//

import SwiftUI
import CoreData

struct OnboardingFlowView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var appState: AppState
    @State private var step = 0
    @State private var selectedGoals: [HealthGoal] = []
    @State private var selectedHabits: [TherapyType] = []
    let onComplete: () -> Void

    private let totalSteps = 5

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Color.cyan : Color.white.opacity(0.15))
                            .frame(height: 3)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

                // Content
                TabView(selection: $step) {
                    ValueDemoStep(onContinue: { withAnimation { step = 1 } })
                        .tag(0)

                    GoalsStep(selectedGoals: $selectedGoals, onContinue: { withAnimation { step = 2 } })
                        .tag(1)

                    HabitsStep(selectedHabits: $selectedHabits, onContinue: {
                        saveHabits()
                        withAnimation { step = 3 }
                    })
                    .tag(2)

                    HealthStep(onContinue: { withAnimation { step = 4 } })
                        .tag(3)

                    PromiseStep(selectedGoals: selectedGoals, onComplete: {
                        appState.hasLaunchedBefore = true
                        appState.hasSelectedTherapyTypes = true
                        onComplete()
                    })
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: step)
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

// MARK: - Health Goals
enum HealthGoal: String, CaseIterable {
    case sleep = "Sleep Better"
    case energy = "More Energy"
    case mood = "Better Mood"
    case recovery = "Faster Recovery"
    case stress = "Less Stress"
    case fitness = "Improve Fitness"

    var icon: String {
        switch self {
        case .sleep: return "moon.zzz.fill"
        case .energy: return "bolt.fill"
        case .mood: return "face.smiling.fill"
        case .recovery: return "heart.circle.fill"
        case .stress: return "leaf.fill"
        case .fitness: return "figure.run"
        }
    }

    var color: Color {
        switch self {
        case .sleep: return .indigo
        case .energy: return .yellow
        case .mood: return .orange
        case .recovery: return .red
        case .stress: return .green
        case .fitness: return .cyan
        }
    }
}

// MARK: - Step 1: Value Demo (Show, don't tell)
struct ValueDemoStep: View {
    let onContinue: () -> Void
    @State private var animationPhase = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated correlation visualization
            VStack(spacing: 24) {
                // Mini insight card
                InsightPreviewCard(animationPhase: animationPhase)
                    .padding(.horizontal, 32)

                // Value proposition
                VStack(spacing: 12) {
                    Text("Discover what actually works")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Track habits. We'll find the patterns\nin your health data.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            // Social proof
            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.cyan.opacity(0.8))
                Text("Join thousands finding what works for them")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.bottom, 24)

            // Button
            Button(action: onContinue) {
                Text("See How It Works")
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
        .onAppear {
            // Animate the insight card
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animationPhase = 1
            }
            withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
                animationPhase = 2
            }
        }
    }
}

// Animated insight preview
struct InsightPreviewCard: View {
    var animationPhase: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "figure.run")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.cyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Morning Runs")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("discovered correlation")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Correlation badge
                Text("+18%")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.green)
                    .opacity(animationPhase >= 2 ? 1 : 0)
            }

            // Mini chart
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    let heights: [CGFloat] = [0.4, 0.5, 0.65, 0.55, 0.75, 0.85, 0.9]
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.8), Color.cyan.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 28, height: animationPhase >= 1 ? heights[i] * 50 : 4)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.05), value: animationPhase)
                }
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)

            // Insight text
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)
                Text("Better sleep quality on days you run")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .opacity(animationPhase >= 2 ? 1 : 0)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Step 2: Goals (Personalization)
struct GoalsStep: View {
    @Binding var selectedGoals: [HealthGoal]
    let onContinue: () -> Void

    private var canContinue: Bool {
        !selectedGoals.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("What do you want to improve?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Select all that apply")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            // Goals grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(HealthGoal.allCases, id: \.self) { goal in
                        GoalTile(
                            goal: goal,
                            isSelected: selectedGoals.contains(goal)
                        ) {
                            toggleGoal(goal)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
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
                    Text(canContinue ? "Continue" : "Select at least 1")
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

    private func toggleGoal(_ goal: HealthGoal) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if selectedGoals.contains(goal) {
            selectedGoals.removeAll { $0 == goal }
        } else {
            selectedGoals.append(goal)
        }
    }
}

struct GoalTile: View {
    let goal: HealthGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(goal.color.opacity(isSelected ? 0.3 : 0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: goal.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(goal.color)
                }

                Text(goal.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.12 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? goal.color : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(goal.color)
                                .padding(10)
                        }
                    }
                    Spacer()
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Step 3: Habits
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
            VStack(spacing: 8) {
                Text("What habits are you curious about?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Pick 2-6 to start tracking")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

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

// MARK: - Step 4: Health Connection
struct HealthStep: View {
    let onContinue: () -> Void

    @State private var isConnecting = false
    @State private var isConnected = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(isConnected ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 120, height: 120)

                if isConnected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.red)
                }
            }
            .padding(.bottom, 40)

            // Text
            VStack(spacing: 16) {
                Text(isConnected ? "Connected!" : "Connect Apple Health")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(isConnected
                     ? "We'll analyze your health data to find\npatterns and correlations."
                     : "We need your health data to discover\nwhat habits actually impact your health.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            // Data types we'll access
            if !isConnected {
                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        DataTypeChip(icon: "heart.fill", label: "Heart Rate", color: .red)
                        DataTypeChip(icon: "bed.double.fill", label: "Sleep", color: .indigo)
                    }
                    HStack(spacing: 20) {
                        DataTypeChip(icon: "figure.walk", label: "Activity", color: .green)
                        DataTypeChip(icon: "waveform.path.ecg", label: "HRV", color: .orange)
                    }
                }
                .padding(.top, 32)
            }

            Spacer()

            // Button
            Button(action: {
                if isConnected {
                    onContinue()
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
                    Text(isConnected ? "Continue" : (isConnecting ? "Connecting..." : "Connect Health"))
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
                withAnimation(.easeOut(duration: 0.3)) {
                    isConnected = true
                }
            }
        }
    }
}

struct DataTypeChip: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Step 5: Promise (Set Expectations)
struct PromiseStep: View {
    let selectedGoals: [HealthGoal]
    let onComplete: () -> Void

    @State private var showInsights = false

    private var primaryGoal: HealthGoal {
        selectedGoals.first ?? .sleep
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Promise
            VStack(spacing: 24) {
                // Sparkle icon
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(.cyan)
                }

                VStack(spacing: 12) {
                    Text("You're all set!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("In about 2 weeks, you'll start seeing\npersonalized insights like these:")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 32)

            // Example insights preview
            VStack(spacing: 12) {
                ExampleInsightRow(
                    icon: primaryGoal.icon,
                    color: primaryGoal.color,
                    text: insightTextFor(primaryGoal)
                )

                if selectedGoals.count > 1 {
                    ExampleInsightRow(
                        icon: selectedGoals[1].icon,
                        color: selectedGoals[1].color,
                        text: insightTextFor(selectedGoals[1])
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .opacity(showInsights ? 1 : 0)
            .offset(y: showInsights ? 0 : 20)

            Spacer()

            // Tip
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text("Log your habits daily for best results")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.bottom, 24)

            // Button
            Button(action: onComplete) {
                Text("Start Discovering")
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showInsights = true
            }
        }
    }

    private func insightTextFor(_ goal: HealthGoal) -> String {
        switch goal {
        case .sleep: return "\"Your sleep improved 23% on meditation days\""
        case .energy: return "\"Morning workouts boost your energy by 18%\""
        case .mood: return "\"Journaling correlates with better mood scores\""
        case .recovery: return "\"Cold exposure speeds up your recovery time\""
        case .stress: return "\"Walks reduce your resting heart rate by 8 bpm\""
        case .fitness: return "\"Consistency matters more than intensity for you\""
        }
    }
}

struct ExampleInsightRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .italic()

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    OnboardingFlowView(onComplete: {})
}
