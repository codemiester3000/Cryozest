import SwiftUI
import JTAppleCalendar

struct LogbookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [])
    private var sessions: FetchedResults<TherapySessionEntity>
    
    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>
    
    var selectedTherapyTypes: [TherapyType] {
        // Convert the selected therapy types from strings to TherapyType values
        if selectedTherapies.isEmpty {
            return [.drySauna, .weightTraining, .coldPlunge, .meditation]
        } else {
            return selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
    }
    
    @State private var therapyType: TherapyType = .drySauna
    @State private var sessionDates = [Date]()
    
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    init() {
        if let firstTherapy = selectedTherapies.first, let therapyType = TherapyType(rawValue: firstTherapy.therapyType ?? "") {
            _therapyType = State(initialValue: therapyType)
        } else {
            _therapyType = State(initialValue: .drySauna)
        }
    }
    
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
                    ForEach(selectedTherapyTypes, id: \.self) { therapyType in
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
                            .background(self.therapyType == therapyType ? therapyType.color : Color.gray)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 5)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
                .padding(.top, 8)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack() {
                                Text("Completed = ")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                
                                Circle()
                                    .fill(self.therapyType.color)
                                    .frame(width: 25, height: 25)
                            }
                            .padding(.leading, 8)
                            .cornerRadius(12)
                            
                            HStack() {
                                Text("Today = ")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 25, height: 25)
                            }
                            .padding(.leading, 8)
                            .cornerRadius(8)
                        }
                        
                        
                        CalendarView(sessionDates: $sessionDates, therapyType: $therapyType)
                            .background(Color(UIColor.darkGray))
                            .frame(height: 300) // Set a fixed height for the calendar
                            .cornerRadius(16)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                        
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
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .onAppear {
                    if let firstTherapy = selectedTherapies.first, let therapyType = TherapyType(rawValue: firstTherapy.therapyType ?? "") {
                        self.therapyType = therapyType
                        updateSessionDates()
                    }
                }
            }
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
