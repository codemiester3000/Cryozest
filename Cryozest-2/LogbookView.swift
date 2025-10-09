import SwiftUI
import JTAppleCalendar

struct LogbookView: View {
    
    @State private var showAddSession = false
    
    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    
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
    
    @State private var sessionDates = [Date]()
    
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    init(therapyTypeSelection: TherapyTypeSelection) {
        self.therapyTypeSelection = therapyTypeSelection
    }
    
    private var sortedSessions: [TherapySessionEntity] {
        let therapyTypeSessions = sessions.filter { $0.therapyType == therapyTypeSelection.selectedTherapyType.rawValue }
        return therapyTypeSessions.sorted(by: { $0.date! > $1.date! }) // changed to sort in descending order
    }
    
    private func updateSessionDates() {
        self.sessionDates = sessions
            .filter { $0.therapyType == therapyTypeSelection.selectedTherapyType.rawValue }
            .compactMap { $0.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background matching app theme
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.25),
                        Color(red: 0.1, green: 0.2, blue: 0.35),
                        Color(red: 0.15, green: 0.25, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Subtle gradient overlay
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.3),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()

                VStack(alignment: .leading) {
                    NavigationLink(destination: ManuallyAddSession(), isActive: $showAddSession) {
                        EmptyView()
                    }
                    VStack {
                        HStack {
                            Text("Activity")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.leading)

                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.trailing, 24)
                            .onTapGesture {
                                showAddSession = true
                            }
                        }
                        .padding(.top, 170)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        CalendarView(sessionDates: $sessionDates, therapyType: $therapyTypeSelection.selectedTherapyType)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                            .frame(height: 300) // Set a fixed height for the calendar
                            .cornerRadius(16)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)

                        if sortedSessions.isEmpty {
                            Text("Begin recording sessions to see data here")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .padding()
                        } else {
                            // Iterate over the sorted sessions
                            ForEach(sortedSessions, id: \.self) { session in
                                SessionRow(session: session, therapyTypeSelection: therapyTypeSelection, therapyTypeName: therapyTypeSelection.selectedTherapyType.displayName(viewContext))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                .onAppear {
                    updateSessionDates()
                }
                .onChange(of: therapyTypeSelection.selectedTherapyType) { _ in
                    updateSessionDates()
                }
                }
            }
        }
    }
}
