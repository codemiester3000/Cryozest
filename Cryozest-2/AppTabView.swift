import SwiftUI

extension Color {
    static let customOrange = Color(red: 255 / 255, green: 140 / 255, blue: 0 / 255)
    static let appleLimeGreen = Color(red: 50.0 / 255, green: 205 / 255, blue: 50 / 255)
}

struct AppTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var sessions: [TherapySession] = []
    @StateObject private var therapyTypeSelection = TherapyTypeSelection()
    
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DailyView(
                recoveryModel: RecoveryGraphModel(selectedDate: Date()),
                exertionModel: ExertionModel(selectedDate: Date()),
                sleepModel: DailySleepViewModel(selectedDate: Date()),
                context: viewContext)
                .tabItem {
                    Image(systemName: "moon")
                    Text("Daily")
                }
                .tag(0)
                .toolbarBackground(.black, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            MainView(therapyTypeSelection: therapyTypeSelection)
                .tabItem {
                    Image(systemName: "stopwatch")
                    Text("Habits")
                }
                .tag(1)
                .toolbarBackground(.black, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            AnalysisView(therapyTypeSelection: therapyTypeSelection)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analysis")
                }
                .tag(2)
                .toolbarBackground(.black, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
        .accentColor(Color.white)
        .opacity(0.85)
        .background(Color.clear)
    }
}
