import SwiftUI

extension Color {
    static let customOrange = Color(red: 255 / 255, green: 140 / 255, blue: 0 / 255)
}

struct AppTabView: View {
    @State private var sessions: [TherapySession] = []
    @StateObject private var therapyTypeSelection = TherapyTypeSelection()

    var body: some View {
        TabView {
            MainView(therapyTypeSelection: therapyTypeSelection)
                .tabItem {
                    Image(systemName: "stopwatch")
                    Text("Stopwatch")
                }
                .toolbarBackground(Color(red: 0.675, green: 0.675, blue: 0.675), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            LogbookView(therapyTypeSelection: therapyTypeSelection)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Logbook")
                }
                .toolbarBackground(Color(red: 0.675, green: 0.675, blue: 0.675), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            AnalysisView(therapyTypeSelection: therapyTypeSelection)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analysis")
                }
                .toolbarBackground(Color(red: 0.675, green: 0.675, blue: 0.675), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
//            DailyView()
//                .tabItem {
//                    Image(systemName: "chart.bar")
//                    Text("Daily")
//                }
        }
        .accentColor(Color.customOrange)
        .opacity(0.85)
        .background(Color.clear)
    }
}
