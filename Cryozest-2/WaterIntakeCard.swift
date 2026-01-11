//
//  WaterIntakeCard.swift
//  Cryozest-2
//
//  Clean, minimal water intake tracking widget
//

import SwiftUI

struct WaterIntakeCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date

    @State private var totalCups: Int = 0
    @State private var animateAdd = false
    @State private var isPressed = false
    @State private var animateProgress = false

    private let dailyGoal = WaterIntake.defaultDailyGoal // 8 cups

    private var progress: Double {
        Double(totalCups) / Double(dailyGoal)
    }

    // Consistent blue color
    private let accentColor = Color(red: 0.3, green: 0.6, blue: 0.95)

    private var statusText: String {
        let status = WaterIntake.hydrationStatus(cups: totalCups, goal: dailyGoal)
        return status.message
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack(alignment: .center) {
                // Icon with glow
                ZStack {
                    if progress >= 0.5 {
                        Circle()
                            .fill(accentColor.opacity(0.25))
                            .frame(width: 44, height: 44)
                            .blur(radius: 6)
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.25), accentColor.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                        )

                    Image(systemName: "drop.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Hydration")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(totalCups)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("/ \(dailyGoal) cups")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()

                // Action buttons
                HStack(spacing: 8) {
                    // Remove button
                    if totalCups > 0 {
                        Button(action: removeCup) {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Add button with glow
                    Button(action: addCup) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.3))
                                .frame(width: 52, height: 52)
                                .blur(radius: 6)

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [accentColor, accentColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )

                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(animateAdd ? 0.88 : 1.0)
                    .shadow(color: accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }

            // Progress bar with glow
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 10)

                        // Glow layer
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.8), accentColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: animateProgress ? geometry.size.width * min(progress, 1.0) : 0, height: 10)
                            .blur(radius: 4)
                            .opacity(0.5)

                        // Main bar
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.9), accentColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: animateProgress ? geometry.size.width * min(progress, 1.0) : 0, height: 10)
                            .overlay(
                                // Shine effect
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), Color.clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: 5)
                                    .offset(y: -2.5)
                                    .mask(
                                        RoundedRectangle(cornerRadius: 5)
                                            .frame(width: animateProgress ? geometry.size.width * min(progress, 1.0) : 0, height: 10)
                                    )
                            )
                    }
                }
                .frame(height: 10)

                // Info row
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("\(WaterIntake.cupsToOunces(totalCups)) oz")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    if progress >= 1.0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Goal reached!")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.15))
                        )
                    } else {
                        Text(statusText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()
                }
            }
        }
        .padding(20)
        .feedWidgetStyle(style: .activity)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onAppear {
            loadData()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateProgress = true
            }
        }
        .onChange(of: selectedDate) { _ in
            animateProgress = false
            loadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animateProgress = true
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: totalCups)
    }

    private func loadData() {
        if MockDataHelper.useMockData {
            totalCups = MockDataHelper.mockWaterCups
        } else {
            totalCups = WaterIntake.getTotalCups(for: selectedDate, context: viewContext)
        }
    }

    private func addCup() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            animateAdd = true
        }

        WaterIntake.addOneCup(for: selectedDate, context: viewContext)
        totalCups += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                animateAdd = false
            }
        }

        if totalCups == dailyGoal {
            let successGenerator = UINotificationFeedbackGenerator()
            successGenerator.notificationOccurred(.success)
        }
    }

    private func removeCup() {
        guard totalCups > 0 else { return }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        WaterIntake.removeOneCup(for: selectedDate, context: viewContext)
        totalCups -= 1
    }
}

// MARK: - Water Glass Visualization

struct WaterGlassView: View {
    let progress: Double
    let progressColor: Color
    let animateAdd: Bool
    let waveOffset: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let fillHeight = height * min(progress, 1.0)

            ZStack {
                // Glass outline
                GlassShape()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)

                // Water fill with wave
                GlassShape()
                    .fill(Color.clear)
                    .overlay(
                        ZStack {
                            // Water gradient
                            LinearGradient(
                                colors: [
                                    progressColor.opacity(0.8),
                                    progressColor.opacity(0.5),
                                    progressColor.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )

                            // Wave effect
                            WaveShape(offset: waveOffset, percent: progress)
                                .fill(progressColor.opacity(0.4))

                            // Bubbles decoration
                            if progress > 0.1 {
                                BubblesView()
                            }
                        }
                        .mask(
                            VStack {
                                Spacer()
                                Rectangle()
                                    .frame(height: fillHeight)
                            }
                        )
                    )
                    .clipShape(GlassShape())

                // Glass highlight
                GlassShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .padding(1)

                // Drop icon at top when empty
                if progress < 0.1 {
                    Image(systemName: "drop")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.white.opacity(0.3))
                        .offset(y: -10)
                }
            }
            .scaleEffect(animateAdd ? 1.05 : 1.0)
        }
    }
}

// MARK: - Glass Shape

struct GlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topWidth = rect.width * 0.9
        let bottomWidth = rect.width * 0.7
        let topInset = (rect.width - topWidth) / 2
        let bottomInset = (rect.width - bottomWidth) / 2
        let cornerRadius: CGFloat = 6

        // Start at top left
        path.move(to: CGPoint(x: topInset + cornerRadius, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: rect.width - topInset - cornerRadius, y: 0))

        // Top right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width - topInset, y: cornerRadius),
            control: CGPoint(x: rect.width - topInset, y: 0)
        )

        // Right edge (tapered)
        path.addLine(to: CGPoint(x: rect.width - bottomInset, y: rect.height - cornerRadius))

        // Bottom right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width - bottomInset - cornerRadius, y: rect.height),
            control: CGPoint(x: rect.width - bottomInset, y: rect.height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: bottomInset + cornerRadius, y: rect.height))

        // Bottom left corner
        path.addQuadCurve(
            to: CGPoint(x: bottomInset, y: rect.height - cornerRadius),
            control: CGPoint(x: bottomInset, y: rect.height)
        )

        // Left edge (tapered)
        path.addLine(to: CGPoint(x: topInset, y: cornerRadius))

        // Top left corner
        path.addQuadCurve(
            to: CGPoint(x: topInset + cornerRadius, y: 0),
            control: CGPoint(x: topInset, y: 0)
        )

        return path
    }
}

// MARK: - Wave Shape

struct WaveShape: Shape {
    var offset: CGFloat
    var percent: Double

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let waveHeight: CGFloat = 4
        let yOffset = rect.height * (1 - min(percent, 1.0))

        path.move(to: CGPoint(x: 0, y: yOffset))

        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * 2 + offset)
            let y = yOffset + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Bubbles Decoration

struct BubblesView: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                    .frame(width: CGFloat.random(in: 3...6))
                    .position(
                        x: CGFloat.random(in: geometry.size.width * 0.2...geometry.size.width * 0.8),
                        y: CGFloat.random(in: geometry.size.height * 0.3...geometry.size.height * 0.9)
                    )
            }
        }
    }
}
