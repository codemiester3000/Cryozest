//
//  OnboardingCoordinator.swift
//  Cryozest-2
//
//  Manages the condensed 3-screen onboarding flow
//

import Foundation
import SwiftUI
import CoreData

enum OnboardingScreen {
    case hook
    case habitSelection
    case completion
}

class OnboardingCoordinator: ObservableObject {
    @Published var currentScreen: OnboardingScreen = .hook
    @Published var selectedHabits: [TherapyType] = []
    @Published var hasCompletedOnboarding = false

    func nextScreen() {
        switch currentScreen {
        case .hook:
            currentScreen = .habitSelection
        case .habitSelection:
            currentScreen = .completion
        case .completion:
            completeOnboarding()
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        OnboardingManager.shared.markDailyTabSeen()
        OnboardingManager.shared.markWidgetsConfigured()
    }

    func saveSelectedHabits(context: NSManagedObjectContext) {
        // Delete all existing selections
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SelectedTherapy.fetchRequest()

        do {
            if let results = try context.fetch(fetchRequest) as? [NSManagedObject] {
                for object in results {
                    context.delete(object)
                }
            }

            // Save new selections
            for habit in selectedHabits {
                let selectedTherapy = SelectedTherapy(context: context)
                selectedTherapy.therapyType = habit.rawValue
            }

            try context.save()
        } catch {
            print("Failed to save selected habits: \(error)")
        }
    }
}
