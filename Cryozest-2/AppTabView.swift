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
                    recoveryModel: RecoveryGraphModel(selectedDate: Calendar.current.startOfDay(for: Date())),
                    exertionModel: ExertionModel(selectedDate: Calendar.current.startOfDay(for: Date())),
                    sleepModel: DailySleepViewModel(selectedDate: Calendar.current.startOfDay(for: Date())),
                    context: viewContext)
                    .tag(0)

                HabitsView(therapyTypeSelection: therapyTypeSelection)
                    .environment(\.managedObjectContext, viewContext)
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
    @Environment(\.sizeCategory) var sizeCategory

    private let tabs = [
        TabItem(icon: "moon.fill", title: "Daily", tag: 0),
        TabItem(icon: "stopwatch.fill", title: "Habits", tag: 1),
        TabItem(icon: "lightbulb.fill", title: "Insights", tag: 2)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab.tag
                    }
                }) {
                    VStack(spacing: 5) {
                        // Icon with glow effect when selected
                        ZStack {
                            if selectedTab == tab.tag {
                                // Glow behind icon
                                Image(systemName: tab.icon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.cyan)
                                    .blur(radius: 8)
                                    .opacity(0.6)
                            }

                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: selectedTab == tab.tag ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab.tag ? .cyan : .white.opacity(0.4))
                        }

                        // Label
                        Text(tab.title)
                            .font(.system(size: 11, weight: selectedTab == tab.tag ? .bold : .medium))
                            .foregroundColor(selectedTab == tab.tag ? .white : .white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        // Selected tab highlight
                        Group {
                            if selectedTab == tab.tag {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cyan.opacity(0.15))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(tab.title)
                .accessibilityHint("Tab \(tab.tag + 1) of \(tabs.count)")
                .accessibilityAddTraits(selectedTab == tab.tag ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            // Solid darker background for maximum contrast
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.14))
        )
        .overlay(
            // Prominent cyan accent border
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.5),
                            Color.cyan.opacity(0.2),
                            Color.cyan.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.cyan.opacity(0.15), radius: 20, x: 0, y: 0)
        .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Navigation tabs")
    }
}

struct TabItem {
    let icon: String
    let title: String
    let tag: Int
}
