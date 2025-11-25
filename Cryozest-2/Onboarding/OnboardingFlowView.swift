//
//  OnboardingFlowView.swift
//  Cryozest-2
//
//  Tight 4-step onboarding with beautiful animations
//  Flow: Value Demo → Habits → Health → Promise
//

import SwiftUI
import CoreData

struct OnboardingFlowView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var appState: AppState
    @State private var step = 0
    @State private var selectedHabits: [TherapyType] = []
    let onComplete: () -> Void

    private let totalSteps = 4

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Progress bar with animation
                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Color.cyan : Color.white.opacity(0.15))
                            .frame(height: 3)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

                // Content
                TabView(selection: $step) {
                    ValueDemoStep(onContinue: { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { step = 1 } })
                        .tag(0)

                    HabitsStep(selectedHabits: $selectedHabits, onContinue: {
                        saveHabits()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { step = 2 }
                    })
                    .tag(1)

                    HealthStep(onContinue: { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { step = 3 } })
                        .tag(2)

                    PromiseStep(onComplete: {
                        appState.hasLaunchedBefore = true
                        appState.hasSelectedTherapyTypes = true
                        onComplete()
                    })
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
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

// MARK: - Animated Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.10, blue: 0.18),
                Color(red: 0.08, green: 0.12, blue: 0.22),
                Color(red: 0.06, green: 0.10, blue: 0.18)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Step 1: Value Demo
struct ValueDemoStep: View {
    let onContinue: () -> Void

    @State private var showCard = false
    @State private var chartAnimated = false
    @State private var showInsight = false
    @State private var showText = false
    @State private var showButton = false
    @State private var pulseRing = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated insight card
            VStack(spacing: 28) {
                // Card with pulse ring
                ZStack {
                    // Pulse ring
                    Circle()
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        .frame(width: 320, height: 320)
                        .scaleEffect(pulseRing ? 1.1 : 0.9)
                        .opacity(pulseRing ? 0 : 0.5)

                    InsightCard(chartAnimated: chartAnimated, showInsight: showInsight)
                        .padding(.horizontal, 32)
                        .scaleEffect(showCard ? 1 : 0.8)
                        .opacity(showCard ? 1 : 0)
                }

                // Value proposition
                VStack(spacing: 14) {
                    Text("Discover what works")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)

                    Text("Track habits. We find the patterns.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 20)
            }

            Spacer()

            // Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onContinue()
            }) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cyan)
                            .shadow(color: Color.cyan.opacity(0.4), radius: 12, x: 0, y: 4)
                    )
            }
            .scaleEffect(showButton ? 1 : 0.9)
            .opacity(showButton ? 1 : 0)
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showCard = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                chartAnimated = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
                showInsight = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6)) {
                showText = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.0)) {
                showButton = true
            }
            // Pulse animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false).delay(0.5)) {
                pulseRing = true
            }
        }
    }
}

struct InsightCard: View {
    var chartAnimated: Bool
    var showInsight: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "figure.run")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.cyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Morning Runs")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("correlation found")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Badge
                Text("+23%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
                    .opacity(showInsight ? 1 : 0)
                    .scaleEffect(showInsight ? 1 : 0.5)
            }

            // Animated chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    let heights: [CGFloat] = [0.35, 0.5, 0.65, 0.45, 0.8, 0.7, 0.95]
                    let colors: [Color] = [.cyan.opacity(0.5), .cyan.opacity(0.6), .cyan.opacity(0.7), .cyan.opacity(0.55), .cyan.opacity(0.85), .cyan.opacity(0.75), .cyan]

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [colors[i], colors[i].opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: chartAnimated ? heights[i] * 60 : 4)
                        .frame(maxWidth: .infinity)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(i) * 0.08),
                            value: chartAnimated
                        )
                }
            }
            .frame(height: 60)

            // Insight
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text("Better sleep on days you run")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .opacity(showInsight ? 1 : 0)
            .offset(y: showInsight ? 0 : 10)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.5), Color.cyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Step 2: Habits
struct HabitsStep: View {
    @Binding var selectedHabits: [TherapyType]
    let onContinue: () -> Void

    @State private var category: Category = .category0
    @State private var showContent = false
    @State private var showButton = false
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
                Text("What do you want to track?")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Text("Pick 2-6 habits you're curious about")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : -10)
            .padding(.top, 24)
            .padding(.horizontal, 24)

            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(Category.allCases.enumerated()), id: \.element) { index, cat in
                        CategoryPill(
                            category: cat,
                            isSelected: category == cat,
                            showContent: showContent,
                            delay: Double(index) * 0.05
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                category = cat
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }

            // Grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(TherapyType.therapies(forCategory: category).enumerated()), id: \.element) { index, type in
                        HabitTile(
                            type: type,
                            name: type.displayName(managedObjectContext),
                            isSelected: selectedHabits.contains(type),
                            syncs: category == .category0,
                            showContent: showContent,
                            delay: Double(index) * 0.03
                        ) {
                            toggleHabit(type)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 140)
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

                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onContinue()
                }) {
                    HStack(spacing: 8) {
                        Text(canContinue ? "Continue" : "Select at least 2")
                            .font(.system(size: 17, weight: .semibold))

                        if canContinue {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(canContinue ? .black : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canContinue ? Color.cyan : Color.white.opacity(0.1))
                            .shadow(color: canContinue ? Color.cyan.opacity(0.3) : .clear, radius: 12, x: 0, y: 4)
                    )
                }
                .disabled(!canContinue)
                .scaleEffect(showButton ? 1 : 0.95)
                .opacity(showButton ? 1 : 0)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .background(Color(red: 0.06, green: 0.10, blue: 0.18))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                showButton = true
            }
        }
    }

    private func toggleHabit(_ type: TherapyType) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedHabits.contains(type) {
                selectedHabits.removeAll { $0 == type }
            } else if selectedHabits.count < 6 {
                selectedHabits.append(type)
            }
        }
    }
}

struct CategoryPill: View {
    let category: Category
    let isSelected: Bool
    let showContent: Bool
    let delay: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if category == .category0 {
                    Image(systemName: "applewatch")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .scaleEffect(showContent ? 1 : 0.8)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay), value: showContent)
    }
}

struct HabitTile: View {
    let type: TherapyType
    let name: String
    let isSelected: Bool
    let syncs: Bool
    let showContent: Bool
    let delay: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(type.color.opacity(isSelected ? 0.3 : 0.15))
                        .frame(width: 50, height: 50)
                        .scaleEffect(isSelected ? 1.1 : 1.0)

                    Image(systemName: type.icon)
                        .font(.system(size: 22, weight: .medium))
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
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isSelected ? 0.12 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? type.color : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(type.color)
                                .padding(8)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    Spacer()
                }
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
        .scaleEffect(showContent ? 1 : 0.8)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay), value: showContent)
    }
}

struct OnboardingScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Step 3: Health Connection
struct HealthStep: View {
    let onContinue: () -> Void

    @State private var isConnecting = false
    @State private var isConnected = false
    @State private var showContent = false
    @State private var showChips = false
    @State private var pulseHeart = false
    @State private var rotateRing = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated heart icon
            ZStack {
                // Rotating ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Color.red.opacity(0.5), Color.red.opacity(0.1), Color.red.opacity(0.5)],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(rotateRing ? 360 : 0))
                    .opacity(isConnected ? 0 : 1)

                // Pulse circles
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulseHeart ? 1.2 : 1.0)
                    .opacity(pulseHeart ? 0 : 0.5)

                Circle()
                    .fill(isConnected ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 120, height: 120)

                if isConnected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 54))
                        .foregroundColor(.red)
                        .scaleEffect(pulseHeart ? 1.05 : 1.0)
                }
            }
            .padding(.bottom, 40)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)

            // Text
            VStack(spacing: 14) {
                Text(isConnected ? "Connected!" : "Connect Apple Health")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(isConnected
                     ? "We'll find patterns in your data."
                     : "We analyze your health data to\nfind what's working for you.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .padding(.horizontal, 32)

            // Data chips
            if !isConnected {
                HStack(spacing: 12) {
                    ForEach(Array([
                        ("heart.fill", "Heart", Color.red),
                        ("bed.double.fill", "Sleep", Color.indigo),
                        ("figure.walk", "Activity", Color.green),
                        ("waveform.path.ecg", "HRV", Color.orange)
                    ].enumerated()), id: \.offset) { index, item in
                        DataChip(icon: item.0, label: item.1, color: item.2)
                            .opacity(showChips ? 1 : 0)
                            .offset(y: showChips ? 0 : 15)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.08), value: showChips)
                    }
                }
                .padding(.top, 32)
            }

            Spacer()

            // Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if isConnected {
                    onContinue()
                } else {
                    connect()
                }
            }) {
                HStack(spacing: 10) {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    }
                    Text(isConnected ? "Continue" : (isConnecting ? "Connecting..." : "Connect Health"))
                        .font(.system(size: 17, weight: .semibold))

                    if isConnected {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(isConnected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isConnected ? Color.cyan : Color.red)
                        .shadow(color: (isConnected ? Color.cyan : Color.red).opacity(0.3), radius: 12, x: 0, y: 4)
                )
            }
            .disabled(isConnecting)
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
                showChips = true
            }
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseHeart = true
            }
            // Rotate ring
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotateRing = true
            }
        }
    }

    private func connect() {
        isConnecting = true
        HealthKitManager.shared.requestAuthorization { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isConnecting = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isConnected = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

struct DataChip: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 70, height: 56)
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

// MARK: - Step 4: Promise
struct PromiseStep: View {
    let onComplete: () -> Void

    @State private var showContent = false
    @State private var showInsights = false
    @State private var showButton = false
    @State private var sparkleRotation = false
    @State private var confettiVisible = false

    var body: some View {
        ZStack {
            // Confetti particles
            if confettiVisible {
                ConfettiView()
            }

            VStack(spacing: 0) {
                Spacer()

                // Sparkle icon
                ZStack {
                    // Glow
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)

                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "sparkles")
                        .font(.system(size: 46, weight: .medium))
                        .foregroundColor(.cyan)
                        .rotationEffect(.degrees(sparkleRotation ? 10 : -10))
                }
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)

                VStack(spacing: 14) {
                    Text("You're all set!")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)

                    Text("Start tracking and we'll show you\ninsights in about 2 weeks")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .padding(.top, 32)
                .padding(.horizontal, 32)

                // Example insights
                VStack(spacing: 10) {
                    InsightPreviewRow(
                        icon: "moon.zzz.fill",
                        color: .indigo,
                        text: "Sleep improved 23% on meditation days"
                    )
                    .opacity(showInsights ? 1 : 0)
                    .offset(x: showInsights ? 0 : -30)

                    InsightPreviewRow(
                        icon: "bolt.fill",
                        color: .yellow,
                        text: "Morning runs boost your energy"
                    )
                    .opacity(showInsights ? 1 : 0)
                    .offset(x: showInsights ? 0 : -30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: showInsights)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                Spacer()

                // Tip
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text("Log habits daily for best results")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                .opacity(showInsights ? 1 : 0)
                .padding(.bottom, 24)

                // Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onComplete()
                }) {
                    HStack(spacing: 8) {
                        Text("Start Discovering")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cyan)
                            .shadow(color: Color.cyan.opacity(0.4), radius: 12, x: 0, y: 4)
                    )
                }
                .scaleEffect(showButton ? 1 : 0.9)
                .opacity(showButton ? 1 : 0)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Confetti burst
            withAnimation {
                confettiVisible = true
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) {
                showInsights = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) {
                showButton = true
            }
            // Sparkle wobble
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                sparkleRotation = true
            }
        }
    }
}

struct InsightPreviewRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Confetti Effect
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
        }
    }

    private func createParticles() {
        let colors: [Color] = [.cyan, .green, .yellow, .orange, .pink, .purple]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for i in 0..<30 {
            let particle = ConfettiParticle(
                id: i,
                position: CGPoint(x: screenWidth / 2, y: screenHeight / 3),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...8),
                opacity: 1.0
            )
            particles.append(particle)

            // Animate each particle
            withAnimation(.easeOut(duration: Double.random(in: 1.0...2.0)).delay(Double(i) * 0.02)) {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: 20...(screenWidth - 20)),
                    y: CGFloat.random(in: (screenHeight / 2)...(screenHeight - 100))
                )
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double
}

#Preview {
    OnboardingFlowView(onComplete: {})
}
