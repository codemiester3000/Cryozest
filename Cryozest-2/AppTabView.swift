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
            
            TimerSelectionView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("Timer")
                }
            
            LogbookView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Logbook")
                }
        }
        .accentColor(.blue)
    }
}
