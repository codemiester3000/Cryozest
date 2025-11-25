//
//  WaterIntakeCard.swift
//  Cryozest-2
//
//  Water intake tracking widget with unique glass fill visualization
//

import SwiftUI

struct WaterIntakeCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date

    @State private var totalCups: Int = 0
    @State private var animateAdd = false
    @State private var waveOffset: CGFloat = 0

    private let dailyGoal = WaterIntake.defaultDailyGoal // 8 cups

    private var progress: Double {
        Double(totalCups) / Double(dailyGoal)
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return Color(red: 0.0, green: 0.8, blue: 0.9) // Bright cyan
        } else if progress >= 0.75 {
            return Color(red: 0.2, green: 0.7, blue: 0.9)
        } else if progress >= 0.5 {
            return Color(red: 0.3, green: 0.6, blue: 0.85)
        } else if progress >= 0.25 {
            return Color(red: 0.4, green: 0.5, blue: 0.8)
        } else {
            return Color(red: 0.5, green: 0.6, blue: 0.9)
        }
    }

    private var statusText: String {
        let status = WaterIntake.hydrationStatus(cups: totalCups, goal: dailyGoal)
        return status.message
    }

    var body: some View {
        HStack(spacing: 16) {
            // Water glass visualization
            WaterGlassView(
                progress: progress,
                progressColor: progressColor,
                animateAdd: animateAdd,
                waveOffset: waveOffset
            )
            .frame(width: 48, height: 64)

            // Content
            VStack(alignment: .leading, spacing: 10) {
                // Header row
                HStack {
                    Text("Hydration")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    // Status badge
                    if progress >= 1.0 {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("Done")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .fixedSize()
                    }
                }

                // Large cup count
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(totalCups)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("/ \(dailyGoal) cups")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                // Info row
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                            .foregroundColor(progressColor.opacity(0.8))
                        Text("\(WaterIntake.cupsToOunces(totalCups)) oz")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Text("•")
                        .foregroundColor(.white.opacity(0.3))

                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(progressColor)
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 10) {
                // Add button
                Button(action: addCup) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.6, blue: 0.9),
                                        Color(red: 0.1, green: 0.4, blue: 0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: Color.blue.opacity(0.4), radius: 6, y: 3)

                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(animateAdd ? 0.9 : 1.0)

                // Remove button
                if totalCups > 0 {
                    Button(action: removeCup) {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(20)
        .modernWidgetCard(style: .activity)
        .onAppear {
            loadData()
            // Start wave animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                waveOffset = .pi * 2
            }
        }
        .onChange(of: selectedDate) { _ in
            loadData()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: totalCups)
    }

    private func loadData() {
        totalCups = WaterIntake.getTotalCups(for: selectedDate, context: viewContext)
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
