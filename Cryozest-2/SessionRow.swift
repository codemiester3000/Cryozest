import SwiftUI

struct SessionRow: View {
    var session: TherapySessionEntity

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.date ?? "")
                    .font(.system(size: 24, weight: .bold, design: .rounded)) // Use the rounded design for a modern look
                    .foregroundColor(.white)
//                    .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 2) // Add shadow to improve readability
                
                Text(session.therapyType ?? "")
                    .font(.system(size: 18, design: .rounded)) // Use the rounded design for a modern look
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
//                    .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 2) // Add shadow to improve readability
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text("Duration: \(String(format: "%02d", Int(session.duration) / 60)):\(String(format: "%02d", Int(session.duration) % 60))")
                    .font(.system(size: 18, design: .rounded)) // Use the rounded design for a modern look
                    .foregroundColor(.white)
//                    .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 2) // Add shadow to improve readability
                
                Text("Temp: \(Int(session.temperature))°F")
                    .font(.system(size: 18, design: .rounded)) // Use the rounded design for a modern look
                    .foregroundColor(.white)
//                    .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 2) // Add shadow to improve readability
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
