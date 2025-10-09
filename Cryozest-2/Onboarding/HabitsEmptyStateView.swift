//
//  HabitsEmptyStateView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

struct HabitsEmptyStateView: View {
    let therapyColor: Color
    let onDismiss: () -> Void

    @State private var animatePulse = false
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                therapyColor.opacity(0.3),
                                therapyColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(animatePulse ? 1.15 : 1.0)
                    .opacity(animatePulse ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animatePulse)

                Image(systemName: "stopwatch.fill")
                    .font(.system(size: 45, weight: .regular))
                    .foregroundColor(therapyColor)
            }

            VStack(spacing: 12) {
                Text("Start Your First Session")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Choose a habit above and tap Start to begin tracking your wellness journey")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Quick tips
            VStack(alignment: .leading, spacing: 14) {
                TipRow(number: "1", text: "Swipe through habits to explore different wellness activities")
                TipRow(number: "2", text: "Use the stopwatch to track your sessions in real-time")
                TipRow(number: "3", text: "Or quickly mark today as complete if you've already finished")
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)

            Spacer()

            // Dismiss button
            Button(action: onDismiss) {
                HStack(spacing: 10) {
                    Text("Got it!")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            therapyColor,
                            therapyColor.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: therapyColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            animatePulse = true
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

struct TipRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.2))
                    .frame(width: 28, height: 28)

                Text(number)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
            }

            Text(text)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}
