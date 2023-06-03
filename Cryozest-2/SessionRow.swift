import SwiftUI

struct SessionRow: View {
    var session: TherapySessionEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.date ?? "")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                Spacer()
                Text(session.therapyType ?? "")
                    .font(.system(size: 20, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
            
            HStack {
                Text("Duration: \(formattedDuration)")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                Spacer()
                Text("Temp: \(Int(session.temperature))°F")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
            
            // Health Metrics
            VStack(alignment: .leading, spacing: 10) {
                HeartRateView(title: "Average Heart Rate", value: session.averageHeartRate)
                HeartRateView(title: "Min Heart Rate", value: session.minHeartRate, maxValue: 1000)
                HeartRateView(title: "Max Heart Rate", value: session.maxHeartRate)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(Color(.darkGray))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
    }
    
    private func HeartRateView(title: String, value: Double, maxValue: Double = 0) -> some View {
        HStack {
            if value != maxValue {
                Image(systemName: "heart.fill")
                    .foregroundColor(.orange)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                Text("\(title): \(value) bpm")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
        }
    }
    
    private var formattedDuration: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
