import SwiftUI

struct SessionRow: View {
    var session: LogbookView.Session

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.date)
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(.white) // Change date text color to blue
                Text(session.therapyType.rawValue)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Duration: \(session.formattedDuration)")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white)
                Text("Temp: \(session.temperature)°F")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white)
                Text("Humidity: \(session.humidity)%")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(.blue)
        .cornerRadius(8)
    }
}
