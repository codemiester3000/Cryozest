import SwiftUI

struct LogbookView: View {
    @Binding var sessions: [Session]

    var body: some View {
        NavigationView {
            List {
                ForEach(sessions) { session in
                    SessionRow(session: session)
                }
            }
            .navigationBarTitle("Logbook", displayMode: .inline)
        }
    }
}

extension LogbookView {
    struct Session: Codable, Identifiable {
        let id: UUID
        let date: String
        let duration: TimeInterval
        let temperature: Int
        let humidity: Int
        let therapyType: TherapyType
        
        init(date: String, duration: TimeInterval, temperature: Int, humidity: Int, therapyType: TherapyType) {
            self.id = UUID()
            self.date = date
            self.duration = duration
            self.temperature = temperature
            self.humidity = humidity
            self.therapyType = therapyType
        }
        
        var formattedDuration: String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

