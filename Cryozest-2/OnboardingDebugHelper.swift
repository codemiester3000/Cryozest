//
//  OnboardingDebugHelper.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

/// Debug helper view to reset onboarding state for testing
/// To use: Add this view to your settings or as a hidden gesture somewhere in the app
struct OnboardingDebugView: View {
    @State private var showAlert = false

    var body: some View {
        Button(action: {
            showAlert = true
        }) {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 18))
                Text("Reset Onboarding")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.orange)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .alert("Reset Onboarding?", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                OnboardingManager.shared.resetOnboarding()
            }
        } message: {
            Text("This will reset all onboarding flags and show the empty states again on next launch.")
        }
    }
}

// Extension to add a triple-tap gesture to any view for debug access
extension View {
    func onboardingDebugGesture() -> some View {
        self.onTapGesture(count: 3) {
            OnboardingManager.shared.resetOnboarding()
            print("🔄 Onboarding reset! Restart the app to see empty states.")
        }
    }
}
