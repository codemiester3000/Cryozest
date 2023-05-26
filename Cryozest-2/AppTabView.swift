import SwiftUI

extension Color {
    static let customGray = Color(red: 0.9, green: 0.9, blue: 0.9)
}

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
        }
        .accentColor(Color(red: 168/255 * 0.5, green: 191/255 * 0.5, blue: 135/255 * 0.5))
        .background(Color.clear)
        
    }
}
