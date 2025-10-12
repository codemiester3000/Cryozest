//
//  SafetyWarningView.swift
//  Cryozest-2
//
//  Created by owenkhoury on 10/12/25.
//

import SwiftUI

struct SafetyWarningView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Modern gradient background matching app theme
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
                    Color.orange.opacity(0.3),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Warning Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.orange.opacity(0.3),
                                    Color.orange.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .padding(.bottom, 16)

                // Title
                Text("Device Safety Notice")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Content Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("This app tracks wellness activities including those in extreme temperatures.")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("IMPORTANT:")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)

                        SafetyBulletPoint(
                            text: "Never bring your iPhone or Apple Watch into saunas, hot yoga, or ice baths"
                        )

                        SafetyBulletPoint(
                            text: "Apple devices operate safely between 32°F - 95°F (0°C - 35°C)"
                        )

                        SafetyBulletPoint(
                            text: "Use \"Quick Add\" to log sessions after completion"
                        )

                        SafetyBulletPoint(
                            text: "Or start timer BEFORE entering, then leave device outside"
                        )
                    }

                    Text("Your safety and device protection are important to us.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(4)
                        .padding(.top, 8)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.08)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                        )
                )
                .shadow(color: Color.orange.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 24)

                Spacer()

                // Continue Button
                Button(action: onDismiss) {
                    HStack(spacing: 10) {
                        Text("I Understand")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.orange,
                                Color.orange.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.orange.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct SafetyBulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.orange)

            Text(text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
    }
}

#Preview {
    SafetyWarningView(onDismiss: {})
}
