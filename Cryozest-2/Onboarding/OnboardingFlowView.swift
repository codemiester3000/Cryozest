//
//  OnboardingFlowView.swift
//  Cryozest-2
//
//  Condensed 3-screen onboarding flow
//

import SwiftUI
import CoreData

struct OnboardingFlowView: View {
    @StateObject private var coordinator = OnboardingCoordinator()
    @Environment(\.managedObjectContext) var managedObjectContext
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            switch coordinator.currentScreen {
            case .hook:
                OnboardingHookView(onContinue: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        coordinator.nextScreen()
                    }
                })
                .transition(.opacity)

            case .habitSelection:
                OnboardingHabitSelectionView(
                    selectedHabits: $coordinator.selectedHabits,
                    onContinue: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            coordinator.saveSelectedHabits(context: managedObjectContext)
                            coordinator.nextScreen()
                        }
                    }
                )
                .transition(.opacity)

            case .completion:
                OnboardingCompletionView(onComplete: {
                    coordinator.completeOnboarding()
                    onComplete()
                })
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.currentScreen)
    }
}

#Preview {
    OnboardingFlowView(onComplete: {})
}
