import SwiftUI

struct AppTabView: View {
    @State private var sessions: [TherapySession] = []
    @State private var timerDuration: TimeInterval = 0
    
    var body: some View {
        TabView {
            MainView(sessions: $sessions)
                .tabItem {
                    Image(systemName: "stopwatch")
                    Text("Stopwatch")
                }
            
            TimerSelectionView(timerDuration: $timerDuration)
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
        .accentColor(.white)
    }
}
