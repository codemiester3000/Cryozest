import SwiftUI

struct SessionRow: View {
    var session: TherapySessionEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formattedDate)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                Spacer()
                Text(session.therapyType ?? "")
                    .font(.system(size: 20, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
            
            HStack {
                Text("\(formattedDuration)")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                Spacer()
                Text("\(Int(session.temperature))°F")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
            
            // Health Metrics
            VStack(alignment: .leading, spacing: 10) {
                if session.averageHeartRate > 0 {
                    HeartRateView(title: "Average Heart Rate", value: session.averageHeartRate)
                }
                if session.minHeartRate > 0 {
                    HeartRateView(title: "Min Heart Rate", value: session.minHeartRate, maxValue: 1000)
                }
                if session.maxHeartRate > 0 {
                    HeartRateView(title: "Max Heart Rate", value: session.maxHeartRate)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(Color(.darkGray))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
    }
    
    private var formattedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "MM/dd/yyyy"
        
        guard let date = inputFormatter.date(from: session.date ?? "") else {
            return ""
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .long
        return outputFormatter.string(from: date)
    }
    
    private var formattedDuration: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        
        if minutes == 0 {
            return "\(seconds) secs"
        } else {
            return "\(minutes) mins \(seconds) secs"
        }
    }
    
    private func HeartRateView(title: String, value: Double, maxValue: Double = 0) -> some View {
        let roundedValue = Int((value * 10).rounded() / 10)
        return HStack {
            if Double(roundedValue) != maxValue {
                Image(systemName: "heart.fill")
                    .foregroundColor(.orange)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                Text("\(title): \(roundedValue) bpm")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
        }
    }
}
