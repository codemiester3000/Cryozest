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
            VStack {
                if session.isAppleWatch {
                    HStack {
                        Image(systemName: "applewatch.watchface")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                            .padding(.leading, 5)
                        Text("Recorded on your Apple Watch")
                            .font(.system(size: 12))
                        
                        Spacer()
                    }
                }
                HStack {
                    Text("Completed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    Spacer()
                    Text(therapyTypeName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                }
                .padding(.vertical, 2)
                
                HStack {
                    Text(formattedDuration)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 2)
            }
            
            HStack {
                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                Spacer()
                
                Button(action: {
                    self.showingDeleteAlert = true
                }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .cornerRadius(32)
        .shadow(radius: 5)
        .background(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
}
