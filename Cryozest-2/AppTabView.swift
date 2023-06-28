import SwiftUI

struct AppTabView: View {
    @State private var sessions: [TherapySession] = []
    
    var body: some View {
        TabView {
            MainView(sessions: $sessions)
                .tabItem {
                    Image(systemName: "stopwatch")
                    Text("Stopwatch")
                }
                .toolbarBackground(Color(red: 0.675, green: 0.675, blue: 0.675), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            LogbookView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Logbook")
                }
                .toolbarBackground(Color(red: 0.675, green: 0.675, blue: 0.675), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            AnalysisView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analysis")
                }
                .toolbarBackground(Color(red: 0.675, green: 0.675, blue: 0.675), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
        .accentColor(Color.orange).opacity(0.85)
        .background(Color.clear)
    }
}
