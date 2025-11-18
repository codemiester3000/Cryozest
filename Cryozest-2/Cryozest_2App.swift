import SwiftUI
import CoreData

@main
struct Cryozest_2App: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                } else {
                    // Skip WelcomeView and TherapyTypeSelectionView - everything is now in the main onboarding
                    AppTabView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(appState)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
