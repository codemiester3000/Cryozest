import SwiftUI
import CoreData

@main
struct Cryozest_2App: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.hasLaunchedBefore {
                if appState.hasSelectedTherapyTypes {
                    AppTabView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(appState)
                } else {
                    TherapyTypeSelectionView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(appState)
                }
            } else {
                WelcomeView()
                    .environmentObject(appState)
            }
        }
    }
}
