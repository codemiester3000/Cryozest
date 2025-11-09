//
//  DailyEmptyStateView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

struct DailyEmptyStateView: View {
    let onEnableHealthKit: () -> Void

    @State private var animateIcon = false
    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Animated icon
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
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)

                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.cyan)
                }
                .padding(.top, 40)

                VStack(spacing: 10) {
                    Text("Track Your Daily Metrics")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }

                // Feature highlights
                VStack(alignment: .leading, spacing: 14) {
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Recovery Score", description: "Track your daily readiness")
                    FeatureRow(icon: "bolt.heart.fill", title: "Heart Metrics", description: "Monitor HRV and heart rate")
                    FeatureRow(icon: "moon.stars.fill", title: "Sleep Quality", description: "Analyze your rest patterns")
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 18)

                // Action button
                Button(action: onEnableHealthKit) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 17))
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
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
                    .cornerRadius(14)
                    .shadow(color: Color.cyan.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
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
                        Color.cyan.opacity(0.2),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 100,
                    endRadius: 500
                )
            }
            .ignoresSafeArea()
        )
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            animateIcon = true
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.cyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
    }
}
