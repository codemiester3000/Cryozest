//
//  SecondOnboardingPage.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 2/15/24.
//

import SwiftUI

struct SecondOnboardingPage: View {
    
    let appState: AppState
    
    @State private var showNext = false
    @State private var requestedAccess = false
    @State private var firstTextOpacity = 0.0
    @State private var secondTextOpacity = 0.0
    @State private var thirdTextOpacity = 0.0
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func requestHealthKitAccess() {
        HealthKitManager.shared.requestAuthorization { success, error in
            if success {
                requestedAccess = true
            }
        }
    }
    
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
                    Color.blue.opacity(0.3),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: requestedAccess ? "checkmark.circle.fill" : "heart.text.square.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan)
                }
                .opacity(requestedAccess ? thirdTextOpacity : firstTextOpacity)

                VStack(spacing: 20) {
                    if requestedAccess {
                        Text("You're all set!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(thirdTextOpacity)

                        Text("Now let's select the habits and exercises you want to track and get insights for")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(5)
                            .padding(.horizontal, 40)
                            .opacity(thirdTextOpacity)
                    } else {
                        Text("Health Data Access")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(firstTextOpacity)

                        Text("HealthKit access provides personalized insights based on your health data")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(5)
                            .padding(.horizontal, 40)
                            .opacity(firstTextOpacity)

                        // Privacy notice card
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.cyan)

                                Text("Privacy First")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }

                            Text("Your data stays on your device. We never store or share your health information.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 32)
                        .opacity(secondTextOpacity)
                    }
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        if (requestedAccess) {
                            showNext = true
                            appState.hasLaunchedBefore = true
                        } else {
                            requestHealthKitAccess()

                            withAnimation(Animation.easeIn(duration: 1.0).delay(0.3)) {
                                thirdTextOpacity = 1.0
                            }
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Text(requestedAccess ? "Choose your habits" : "Continue")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.25))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.white, Color.white.opacity(0.95)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 10)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)

                Spacer()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    firstTextOpacity = 1.0
                }
                withAnimation(Animation.easeOut(duration: 0.8).delay(0.2)) {
                    secondTextOpacity = 1.0
                }
            }
        }
    }
}
