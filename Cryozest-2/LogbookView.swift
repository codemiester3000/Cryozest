import SwiftUI

struct LogbookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: TherapySessionEntity.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: true)]) private var sessions: FetchedResults<TherapySessionEntity>
    // @Binding var sessions: [TherapySession]
    
    var body: some View {
        VStack {
            NavigationView {
                ScrollView {
                    LazyVStack {
                        if sessions.isEmpty {
                            Text("Begin recording sessions to see data here")
                                .foregroundColor(.white)
                                .font(.system(size: 18, design: .rounded))
                                .padding()
                        } else {
                            ForEach(sessions) { session in
                                SessionRow(session: session)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color.darkBackground.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Logbook", displayMode: .inline)
        }
    }
}
