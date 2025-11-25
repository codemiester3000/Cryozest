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
            // Deep navy background
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
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
                            .frame(width: 100, height: 100)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 40)

                    // Title
                    Text("Wellness Disclaimer")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // Content Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("This app helps you track your wellness activities and recovery.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(3)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("IMPORTANT:")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.orange)

                            SafetyBulletPoint(
                                text: "Consult with a healthcare professional before starting any new wellness routine"
                            )

                            SafetyBulletPoint(
                                text: "Use the app's timer and tracking features at your own discretion"
                            )

                            SafetyBulletPoint(
                                text: "Use \"Quick Add\" to log sessions after completion"
                            )

                            SafetyBulletPoint(
                                text: "This app is for informational purposes and is not medical advice"
                            )
                        }

                        Text("Your health and safety are important to us.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(3)
                            .padding(.top, 6)
                    }
                    .padding(20)
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

                    // Continue Button
                    Button(action: onDismiss) {
                        HStack(spacing: 10) {
                            Text("I Understand")
                                .font(.system(size: 17, weight: .bold))
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
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
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

struct SafetyBulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.orange)

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(3)
        }
    }
}

#Preview {
    SafetyWarningView(onDismiss: {})
}
