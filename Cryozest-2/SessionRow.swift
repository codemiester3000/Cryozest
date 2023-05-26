import SwiftUI

struct SessionRow: View {
    var session: TherapySessionEntity
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.date ?? "")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(session.therapyType ?? "")
                        .font(.system(size: 18, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Duration: \(formattedDuration)")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Temp: \(Int(session.temperature))°F")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            Spacer()
            // Health Metrics
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    
                    if session.averageHeartRate != 0 {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.orange)
                            
                            Text("Average Heart Rate: \(Int(session.averageHeartRate)) bpm")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    
                    
                    if session.minHeartRate != 1000 {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.orange)
                            
                            Text("Min Heart Rate: \(Int(session.minHeartRate)) bpm")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    
                    if session.maxHeartRate != 0 {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.orange)
                            
                            Text("Max Heart Rate: \(Int(session.maxHeartRate)) bpm")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(Color(red: 0.2, green: 0.2, blue: 0.2).brightness(0.3))
        .cornerRadius(16)
    }
    
    private var formattedDuration: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
