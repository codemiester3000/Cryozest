import SwiftUI

struct SessionRow: View {
    var session: LogbookView.Session

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.date)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(session.therapyType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Duration: \(session.formattedDuration)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Temp: \(session.temperature)°F")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Humidity: \(session.humidity)%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

