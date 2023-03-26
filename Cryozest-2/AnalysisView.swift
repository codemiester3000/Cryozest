import SwiftUI
import CoreData

struct AnalysisView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: TherapySessionEntity.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: true)]) private var sessions: FetchedResults<TherapySessionEntity>
    
    private func sessionStats() -> [TherapyType: (count: Int, totalTime: TimeInterval)] {
        var stats: [TherapyType: (count: Int, totalTime: TimeInterval)] = [:]

        for session in sessions {
            if let therapyType = TherapyType(rawValue: session.therapyType ?? "") {
                let count = stats[therapyType]?.count ?? 0
                let totalTime = stats[therapyType]?.totalTime ?? 0
                stats[therapyType] = (count + 1, totalTime + session.duration)
            }
        }

        return stats
    }

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(TherapyType.allCases, id: \.self) { therapyType in
                        if let stat = sessionStats()[therapyType] {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(therapyType.rawValue)
                                    .font(.headline)
                                Text("Sessions: \(stat.count)")
                                Text("Total time: \(formatTimeInterval(stat.totalTime))")
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.darkBackground.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Analysis", displayMode: .inline)
    }
    
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: interval) ?? "0s"
    }
}

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView()
    }
}

