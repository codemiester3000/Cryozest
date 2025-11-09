import SwiftUI

extension Color {
    static let customOrange = Color(red: 255 / 255, green: 140 / 255, blue: 0 / 255)
    static let appleLimeGreen = Color(red: 50.0 / 255, green: 205 / 255, blue: 50 / 255)
}

struct AppTabView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>

    @State private var sessions: [TherapySession] = []
    @StateObject private var therapyTypeSelection: TherapyTypeSelection

    @State private var selectedTab: Int = 0

    init() {
        // Create a temporary fetch request to get selected therapies for initialization
        let request = SelectedTherapy.fetchRequest()
        request.sortDescriptors = []

        let context = PersistenceController.shared.container.viewContext
        let results = (try? context.fetch(request)) ?? []

        let therapyTypes: [TherapyType]
        if results.isEmpty {
            // Updated for App Store compliance - removed extreme temperature therapies
            therapyTypes = [.running, .weightTraining, .cycling, .meditation]
        } else {
            therapyTypes = results.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }

        // Updated for App Store compliance
        let initialTherapy = therapyTypes.first ?? .running
        _therapyTypeSelection = StateObject(wrappedValue: TherapyTypeSelection(initialTherapyType: initialTherapy))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DailyView(
                    recoveryModel: RecoveryGraphModel(selectedDate: Date()),
                    exertionModel: ExertionModel(selectedDate: Date()),
                    sleepModel: DailySleepViewModel(selectedDate: Date()),
                    context: viewContext)
                    .tag(0)

                MainView(therapyTypeSelection: therapyTypeSelection)
                    .tag(1)

                InsightsView()
                    .environment(\.managedObjectContext, viewContext)
                    .tag(2)
            }
            .accentColor(.cyan)

            // Custom floating tab bar
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .onAppear {
            // Hide the default tab bar
            UITabBar.appearance().isHidden = true
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selectedTab: Int

    private let tabs = [
        TabItem(icon: "moon.fill", title: "Daily", tag: 0),
        TabItem(icon: "stopwatch.fill", title: "Habits", tag: 1),
        TabItem(icon: "lightbulb.fill", title: "Insights", tag: 2)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab.tag
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(selectedTab == tab.tag ? .cyan : .white.opacity(0.5))

                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab.tag ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab.tag ? .cyan : .white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab.tag ?
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cyan.opacity(0.15))
                            : nil
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

struct TabItem {
    let icon: String
    let title: String
    let tag: Int
}
