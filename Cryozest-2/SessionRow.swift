import SwiftUI

struct SessionRow: View {
    var session: LogbookView.Session
    
    var body: some View {
        HStack {
            Text("Date: \(session.date)")
            Spacer()
            Text("Duration: \(String(format: "%02d:%02d", Int(session.duration) / 60, Int(session.duration) % 60))")
            Spacer()
            Text("Temperature: \(session.temperature)°C")
            Spacer()
            Text("Humidity: \(session.humidity)%")
        }
        .padding()
    }
}
