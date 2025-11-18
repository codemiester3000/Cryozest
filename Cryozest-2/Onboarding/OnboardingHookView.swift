//
//  OnboardingHookView.swift
//  Cryozest-2
//
//  Screen 1: The Hook - Clear value proposition in 3 seconds
//

import SwiftUI

struct OnboardingHookView: View {
    let onContinue: () -> Void

    @State private var animate = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            VStack(spacing: 40) {
                Spacer()

                // Animated mockup of Daily tab
                mockupPreview
                    .scaleEffect(animate ? 1.0 : 0.95)
                    .opacity(animate ? 1.0 : 0.8)

                // Value proposition
                VStack(spacing: 16) {
                    Text("Track Health.\nBuild Habits.\nSee Connections.")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)

                    Text("Your Apple Watch collects amazing health data.\nCryozest shows you what it means.")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                // Continue button
                Button(action: onContinue) {
                    HStack(spacing: 12) {
                        Text("Continue")
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
                                Color.cyan,
                                Color.cyan.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.cyan.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 120)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                gradient: Gradient(colors: [
                    Color.cyan.opacity(0.3),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 100,
                endRadius: 500
            )
        }
        .ignoresSafeArea()
    }

    private var mockupPreview: some View {
        VStack(spacing: 12) {
            // Mini health widgets preview
            HStack(spacing: 10) {
                miniWidget(icon: "heart.fill", color: .red, value: "62")
                miniWidget(icon: "figure.walk", color: .green, value: "8.2K")
                miniWidget(icon: "bolt.fill", color: .orange, value: "HRV")
            }

            // Data flowing animation
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(Color.cyan.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animate ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animate
                        )
                }
            }
            .padding(.vertical, 8)

            Text("Real-time insights")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.cyan.opacity(0.8))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func miniWidget(icon: String, color: Color, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 80, height: 70)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    OnboardingHookView(onContinue: {})
}
