import SwiftUI

struct LogbookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: TherapySessionEntity.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: true)]) private var sessions: FetchedResults<TherapySessionEntity>
    // @Binding var sessions: [TherapySession]
    
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
            .background(Color.darkBackground.edgesIgnoringSafeArea(.all)) // Apply the background color to the entire view
            .navigationBarTitle("Logbook", displayMode: .inline)
            
        }
    }
}
