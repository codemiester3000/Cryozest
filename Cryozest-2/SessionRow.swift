import SwiftUI

struct SessionRow: View {
    var session: TherapySessionEntity

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.date ?? "")
                    .font(.system(size: 22, weight: .bold, design: .monospaced)) // Use the rounded design for a modern look
                    .foregroundColor(.white)
                
                Text(session.therapyType ?? "")
                    .font(.system(size: 18, design: .monospaced)) // Use the rounded design for a modern look
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text("Duration: \(String(format: "%02d", Int(session.duration) / 60)):\(String(format: "%02d", Int(session.duration) % 60))")
                    .font(.system(size: 16, design: .monospaced)) // Use the rounded design for a modern look
                    .foregroundColor(.white)
                
                Text("Temp: \(Int(session.temperature))°F")
                    .font(.system(size: 16, design: .monospaced)) // Use the rounded design for a modern look
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(red: 0.2, green: 0.2, blue: 0.2).brightness(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange, lineWidth: 6)
        )
        .cornerRadius(16)
    }
}
