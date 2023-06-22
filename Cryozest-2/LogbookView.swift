import SwiftUI
import JTAppleCalendar

struct LogbookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [])
    private var sessions: FetchedResults<TherapySessionEntity>
    
    @State private var therapyType: TherapyType = .drySauna
    @State private var sessionDates = [Date]()
    
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    private var sortedSessions: [TherapySessionEntity] {
        let therapyTypeSessions = sessions.filter { $0.therapyType == therapyType.rawValue }
        return therapyTypeSessions.sorted(by: { $0.date! > $1.date! }) // changed to sort in descending order
    }
    
    private func updateSessionDates() {
        self.sessionDates = sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("History")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .bold()
                    .padding(.top, 36)
                    .padding(.leading, 24)
                
                LazyVGrid(columns: gridItems, spacing: 10) {
                    ForEach(TherapyType.allCases, id: \.self) { therapyType in
                        Button(action: {
                            self.therapyType = therapyType
                            print("Therapy Type Changed: \(self.therapyType)")
                            updateSessionDates()
                            
                            print("session dates Changed: \(self.sessionDates)")
                        }) {
                            HStack {
                                Image(systemName: therapyType.icon)
                                    .foregroundColor(.white)
                                Text(therapyType.rawValue)
                                    .font(.system(size: 15, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50)
                            .background(self.therapyType == therapyType ?
                                        (therapyType == .coldPlunge || therapyType == .meditation ? Color.blue : Color.orange)
                                        : Color(.gray))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 5)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 5)
                .padding(.top, 20)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        
                        HStack {
                            HStack(spacing: 10) {
                                Text("Completed = ")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))

                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 25, height: 25)
                            }
                            .padding(8)
                            //.background(Color.gray)
                            .cornerRadius(12)

                            HStack(spacing: 10) {
                                Text("Today = ")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))

                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 25, height: 25)
                            }
                            .padding(8)
                            //.background(Color.gray)
                            .cornerRadius(8)
                        }

                        
                        CalendarView(sessionDates: $sessionDates, therapyType: $therapyType)
                            .background(Color(UIColor.darkGray))
                            .frame(height: 300) // Set a fixed height for the calendar
                            .cornerRadius(16)
                            .frame(maxWidth: .infinity)
                        
                        
                        if sortedSessions.isEmpty {
                            Text("Begin recording sessions to see data here")
                                .foregroundColor(.white)
                                .font(.system(size: 18, design: .rounded))
                                .padding()
                        } else {
                            // Iterate over the sorted sessions
                            ForEach(sortedSessions, id: \.self) { session in
                                SessionRow(session: session)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                }
                .onAppear(perform: updateSessionDates)
            }
            //.padding(.horizontal)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}
