import SwiftUI

struct SessionRow: View {
    var session: TherapySessionEntity

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.date ?? "")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(.white)
                Text(session.therapyType ?? "")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Duration: \(Int(session.duration) / 60):\(Int(session.duration) % 60)")
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
