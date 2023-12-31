import SwiftUI

extension Color {
    static let customOrange = Color(red: 255 / 255, green: 140 / 255, blue: 0 / 255)
}

struct AppTabView: View {
    @State private var sessions: [TherapySession] = []
    @StateObject private var therapyTypeSelection = TherapyTypeSelection()
    
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DailyView()
                .tabItem {
                    Image(systemName: "moon")
                    Text("Daily")
                }
                .tag(0)
                .toolbarBackground(.black, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            AnalysisView(therapyTypeSelection: therapyTypeSelection)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analysis")
                }
                .tag(1)
                .toolbarBackground(.black, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            MainView(therapyTypeSelection: therapyTypeSelection)
                .tabItem {
                    Image(systemName: "stopwatch")
                    Text("Stopwatch")
                }
                .tag(2)
                .toolbarBackground(.black, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            LogbookView(therapyTypeSelection: therapyTypeSelection)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(3)
                .toolbarBackground(.black, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
        .accentColor(Color.white)
        .opacity(0.85)
        .background(Color.clear)
    }
}
