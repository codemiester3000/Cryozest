//
//  SplashScreenView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/8/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Modern gradient background
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

            // Subtle gradient overlay
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.cyan.opacity(0.3),
                    Color.clear
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Logo icon
                ZStack {
                    // Outer pulsing circle
                    Circle()
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 0.8)

                    // Icon container
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan.opacity(0.3),
                                        Color.cyan.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
                            )

                        Image(systemName: "snowflake")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.cyan)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App name
                VStack(spacing: 8) {
                    Text("Cryozest")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)

                    Text("Track Your Recovery")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.cyan.opacity(0.8))
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            // Logo animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Text animation (delayed)
            withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }

            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulseAnimation = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
