import SwiftUI

struct AppTabView: View {
    @State private var sessions: [TherapySession] = []
    
    var body: some View {
        TabView {
            MainView(sessions: $sessions)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
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
