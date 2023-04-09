import SwiftUI

struct SessionRow: View {
    var session: TherapySessionEntity

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.date ?? "")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(session.therapyType ?? "")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text("Duration: \(String(format: "%02d", Int(session.duration) / 60)):\(String(format: "%02d", Int(session.duration) % 60))")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                
                Text("Temp: \(Int(session.temperature))°F")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.gray)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange, lineWidth: 4)
        )
        .cornerRadius(16)
    }
}
