import SwiftUI

struct LogbookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]) // Change ascending to false
    private var sessions: FetchedResults<TherapySessionEntity>
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) { // Add more spacing between SessionRow items
                    if sessions.isEmpty {
                        Text("Begin recording sessions to see data here")
                            .foregroundColor(.white)
                            .font(.system(size: 18, design: .rounded))
                            .padding() // Add padding to give the text some space from the edges
                    } else {
                        ForEach(sessions) { session in
                            SessionRow(session: session)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitle("Logbook", displayMode: .inline)
        }
    }
}
