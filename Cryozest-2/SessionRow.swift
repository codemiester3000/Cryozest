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
        VStack(alignment: .leading, spacing: 12) {
            // Apple Watch badge
            if session.isAppleWatch {
                HStack(spacing: 6) {
                    Image(systemName: "applewatch.watchface")
                        .foregroundColor(.cyan)
                        .font(.system(size: 12, weight: .semibold))
                    Text("Apple Watch")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.cyan)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.cyan.opacity(0.15))
                )
            }

            // Status and therapy type
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    Text("Completed")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                }

                Spacer()

                Text(therapyTypeName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(therapyTypeSelection.selectedTherapyType.color.opacity(0.15))
                    )
            }

            // Duration
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                Text(formattedDuration)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Date and delete button
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Text(formattedDate)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Button(action: {
                    self.showingDeleteAlert = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 32, height: 32)

                        Image(systemName: "trash.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
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
