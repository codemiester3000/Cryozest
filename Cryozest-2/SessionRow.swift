import SwiftUI
import HealthKit

struct SessionRow: View {
    var session: TherapySessionEntity
    var therapyTypeSelection: TherapyTypeSelection
    var therapyTypeName: String
    
    @State private var averageHeartRateForDay: Double? = nil
    @State private var averageHRVForDay: Double? = nil
    
    @State private var showingDeleteAlert = false
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date and Therapy Type
            HStack {
                Text(formattedDate)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(therapyTypeName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
            }
            
            Divider().background(Color.white.opacity(0.8))
            
            // Session Metrics
            HStack {
                Label("\(formattedDuration)", systemImage: "clock")
                    .foregroundColor(.white)
                Spacer()
                
                // Delete button
                Button(action: {
                               self.showingDeleteAlert = true // Show the alert when button is tapped
                           }) {
                               Image(systemName: "xmark.circle")
                                   .foregroundColor(.red)
                           }
//                Button(action: deleteSession) {
//                    Image(systemName: "xmark.circle")
//                        .foregroundColor(.red)
//                }
            }
        }
        .padding()
        .cornerRadius(16)
        .shadow(radius: 5)
        .alert(isPresented: $showingDeleteAlert) {
                    Alert(
                        title: Text("Confirm Deletion"),
                        message: Text("Are you sure you want to delete this session?"),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteSession()
                        },
                        secondaryButton: .cancel()
                    )
                }
        .onAppear {
            loadAverageHeartRate()
            loadAverageHRV()
        }
    }
    
    private func deleteSession() {
        managedObjectContext.delete(session)
        try? managedObjectContext.save()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: session.date ?? Date())
    }
    
    private var formattedDuration: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        return minutes == 0 ? "\(seconds) secs" : "\(minutes) mins \(seconds) secs"
    }
    
    //    private func HeartRateView(title: String, value: Double, maxValue: Double = 0) -> some View {
    //        let roundedValue = Int((value * 10).rounded() / 10)
    //        return Group {
    //            if Double(roundedValue) != maxValue {
    //                HStack {
    //                    Image(systemName: "heart.fill")
    //                        .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
    //                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    //                    Text("\(title): \(roundedValue) bpm")
    //                        .font(.system(size: 16, design: .monospaced))
    //                        .foregroundColor(.white)
    //                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    //                }
    //            }
    //        }
    //    }
    
    private func loadAverageHeartRate() {
        guard let sessionDate = session.date else { return }
        HealthKitManager.shared.fetchAvgHeartRateForDays(days: [sessionDate]) { averageHeartRate in
            self.averageHeartRateForDay = averageHeartRate
        }
    }
    
    private func loadAverageHRV() {
        guard let sessionDate = session.date else { return }
        
        HealthKitManager.shared.fetchAvgHRVForDays(days: [sessionDate]) { averageHRV in
            self.averageHRVForDay = averageHRV
        }
    }
}

