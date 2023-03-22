import SwiftUI

struct LogbookView: View {
    @Binding var sessions: [Session]
    
    var body: some View {
        List {
            ForEach(sessions, id: \.date) { session in
                SessionRow(session: session)
            }
        }
        .navigationBarTitle("Logbook", displayMode: .inline)
        .navigationBarItems(leading: Button(action: {
            // Dismiss the LogbookView
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }) {
            Image(systemName: "chevron.backward")
                .font(.system(size: 24))
        })
    }
    
    struct Session: Identifiable {
        let id = UUID()
        var date: String
        var duration: TimeInterval
        var temperature: Int
        var humidity: Int
    }
}
