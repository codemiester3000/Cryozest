import SwiftUI
import CoreData

@main
struct Cryozest_2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Other views go here, below the AppTabView in the ZStack
                // For example, a background color or an image
                Color(.systemBackground).edgesIgnoringSafeArea(.all)

                // Your AppTabView comes here, as the topmost view
                AppTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
