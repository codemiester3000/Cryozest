//
//  OnboardingCompletionView.swift
//  Cryozest-2
//
//  Screen 3: Completion - Request permissions and celebrate
//

import SwiftUI

struct OnboardingCompletionView: View {
    let onComplete: () -> Void

    @State private var showContent = false
    @State private var isConnecting = false
    @State private var healthKitGranted = false
    @State private var showSuccess = false
    @State private var celebrationScale: CGFloat = 0.5
    @State private var celebrationOpacity: Double = 0

    var body: some View {
        ZStack {
            // Deep navy background
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            if !showSuccess {
                // HealthKit permission screen
                VStack(spacing: 40) {
                    Spacer()

                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 120, height: 120)

                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.red)
                    }
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .opacity(showContent ? 1.0 : 0)

                    // Message
                    VStack(spacing: 16) {
                        Text("Connect Your\nHealth Data")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        Text("We'll analyze your health metrics\nand show you meaningful patterns")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    Spacer()

                    // Connect button
                    Button(action: connectHealthKit) {
                        HStack(spacing: 12) {
                            if isConnecting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Connecting...")
                                    .font(.system(size: 18, weight: .semibold))
                            } else {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 18))
                                Text("Connect Health Data")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red,
                                    Color.red.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.red.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .disabled(isConnecting)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 120)
                    .opacity(showContent ? 1 : 0)
                }
            } else {
                // Success screen
                VStack(spacing: 40) {
                    Spacer()

                    // Celebration animation
                    ZStack {
                        // Particles
                        ForEach(0..<12, id: \.self) { index in
                            Circle()
                                .fill(Color.green.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .offset(
                                    x: cos(Double(index) * .pi / 6) * 80 * celebrationScale,
                                    y: sin(Double(index) * .pi / 6) * 80 * celebrationScale
                                )
                                .opacity(celebrationOpacity * 0.8)
                        }

                        // Center checkmark
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .blur(radius: 10)

                            Circle()
                                .fill(Color.green)
                                .frame(width: 90, height: 90)

                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(celebrationScale)
                    }
                    .opacity(celebrationOpacity)

                    // Success message
                    VStack(spacing: 16) {
                        Text("You're All Set!")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        Text("Start tracking your wellness journey")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    // Get started button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onComplete()
                    }) {
                        HStack(spacing: 12) {
                            Text("View Dashboard")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green,
                                    Color.green.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.green.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 120)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }

    private func connectHealthKit() {
        isConnecting = true

        HealthKitManager.shared.requestAuthorization { success, error in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isConnecting = false
                healthKitGranted = success

                // Show success animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccess = true
                }

                // Celebration animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        celebrationScale = 1.2
                        celebrationOpacity = 1
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            celebrationScale = 1.0
                        }
                    }

                    // Fade out celebration
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            celebrationOpacity = 0
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingCompletionView(onComplete: {})
}
