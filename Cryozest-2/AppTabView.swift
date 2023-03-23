import SwiftUI

struct AppTabView: View {
    @State private var sessions: [LogbookView.Session] = []
    
    var body: some View {
        TabView {
            MainView(sessions: $sessions)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            LogbookView(sessions: $sessions)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Logbook")
                }
        }
        .accentColor(.white)
    }
}
