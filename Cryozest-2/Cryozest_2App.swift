import SwiftUI
import CoreData

@main
struct Cryozest_2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
