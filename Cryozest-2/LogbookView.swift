import SwiftUI

struct LogbookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]) // Change ascending to false
    private var sessions: FetchedResults<TherapySessionEntity>

    // A computed property to group sessions by therapy type
    private var groupedSessions: [String: [TherapySessionEntity]] {
        Dictionary(grouping: sessions, by: { $0.therapyType ?? "" })
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("History")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .bold()
                    .padding(.top, 24)
                    .padding(.leading, 16)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if sessions.isEmpty {
                            Text("Begin recording sessions to see data here")
                                .foregroundColor(.white)
                                .font(.system(size: 18, design: .rounded))
                                .padding()
                        } else {
                            // Iterate over the grouped sessions dictionary
                            ForEach(groupedSessions.keys.sorted(), id: \.self) { therapyType in
                                // Add the therapy type header
                                Text(therapyType)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.top)

                                // Iterate over sessions in the current group
                                ForEach(groupedSessions[therapyType] ?? [], id: \.self) { session in
                                    SessionRow(session: session)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .padding(.horizontal) // Add horizontal padding to the VStack
            .background(Color(.sRGB, red: 0.15, green: 0.15, blue: 0.15, opacity: 0.9))
                
            
        }
    }
}

