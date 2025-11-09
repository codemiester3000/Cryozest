//
//  AnalysisEmptyStateView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

struct AnalysisEmptyStateView: View {
    let therapyColor: Color
    let onDismiss: () -> Void

    @State private var animateChart = false
    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Animated chart illustration
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    therapyColor.opacity(0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateChart ? 1.2 : 1.0)
                        .opacity(animateChart ? 0 : 1)
                        .animation(.easeOut(duration: 2).repeatForever(autoreverses: false), value: animateChart)

                    VStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 40, weight: .regular))
                            .foregroundColor(therapyColor)

                        HStack(spacing: 3) {
                            ForEach(0..<3) { index in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(therapyColor.opacity(0.3))
                                    .frame(width: 16, height: CGFloat(24 + index * 12))
                                    .offset(y: animateChart ? -8 : 0)
                                    .animation(
                                        .easeInOut(duration: 0.8)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.2),
                                        value: animateChart
                                    )
                            }
                        }
                    }
                }
                .padding(.top, 40)

                VStack(spacing: 10) {
                    Text("Your Insights Await")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Complete your first session to unlock personalized analytics and track your progress over time")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // What you'll see
                VStack(spacing: 0) {
                    HStack {
                        Text("What You'll Discover")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                    VStack(alignment: .leading, spacing: 14) {
                        InsightRow(icon: "chart.line.uptrend.xyaxis", title: "Consistency Score", subtitle: "Track your habit streaks")
                        InsightRow(icon: "clock.badge.checkmark", title: "Duration Trends", subtitle: "Optimize session length")
                        InsightRow(icon: "calendar.badge.clock", title: "Best Times", subtitle: "Find your ideal schedule")
                        InsightRow(icon: "trophy.fill", title: "Personal Bests", subtitle: "Celebrate milestones")
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(therapyColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)

                // CTA
                Button(action: onDismiss) {
                    HStack(spacing: 10) {
                        Text("Start Tracking")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                therapyColor,
                                therapyColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: therapyColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            animateChart = true
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.cyan)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
    }
}
