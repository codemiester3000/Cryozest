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
                        .onAppear {
                            let currentDate = Date()
                            let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: currentDate)!
                            print("Fetching daily health data for date range: \(threeMonthsAgo) - \(currentDate)")
                            saveDailyHealthData(startDate: threeMonthsAgo, endDate: currentDate)
                        }
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
    
    private func saveDailyHealthData(startDate: Date, endDate: Date) {
        let context = persistenceController.container.viewContext
        let dailyHealthService = DailyHealthService(managedContext: context)
        
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            print("Saving daily health data for date: \(currentDate)")
            dailyHealthService.saveDailyHealthData(date: currentDate) { success in
                if success {
                    print("Daily health data saved successfully for date: \(currentDate)")
                } else {
                    print("Failed to save daily health data for date: \(currentDate)")
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }
}
