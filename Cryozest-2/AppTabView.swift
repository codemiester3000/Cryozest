import SwiftUI
import Combine

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

    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>

    @StateObject private var insightsViewModelWrapper = InsightsViewModelWrapper()
    @State private var selectedTab: Int = 0

    private var selectedTherapyTypes: [TherapyType] {
        if selectedTherapies.isEmpty {
            return [.running, .weightTraining, .cycling, .meditation]
        } else {
            return selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DailyView(
                    recoveryModel: RecoveryGraphModel(selectedDate: Calendar.current.startOfDay(for: Date())),
                    exertionModel: ExertionModel(selectedDate: Calendar.current.startOfDay(for: Date())),
                    sleepModel: DailySleepViewModel(selectedDate: Calendar.current.startOfDay(for: Date())),
                    context: viewContext,
                    insightsViewModel: insightsViewModelWrapper.viewModel
                )
                    .tag(0)

                InsightsTabView(insightsViewModel: insightsViewModelWrapper.viewModel)
                    .environment(\.managedObjectContext, viewContext)
                    .tag(1)
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

            // Initialize the shared insights ViewModel
            if insightsViewModelWrapper.viewModel == nil {
                insightsViewModelWrapper.viewModel = InsightsViewModel(
                    sessions: sessions,
                    selectedTherapyTypes: selectedTherapyTypes,
                    viewContext: viewContext
                )
            }
        }
    }
}

// Wrapper class to hold the optional viewModel as @Published
class InsightsViewModelWrapper: ObservableObject {
    @Published var viewModel: InsightsViewModel? {
        didSet {
            cancellable?.cancel()
            cancellable = viewModel?.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }

    private var cancellable: AnyCancellable?
}

struct FloatingTabBar: View {
    @Binding var selectedTab: Int

    private let tabs = [
        TabItem(icon: "sun.max.fill", title: "Today", tag: 0),
        TabItem(icon: "chart.bar.fill", title: "Insights", tag: 1)
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.tag) { tab in
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab.tag
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .medium))

                        Text(tab.title)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(selectedTab == tab.tag ? .white : .white.opacity(0.35))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(selectedTab == tab.tag
                                  ? Color.white.opacity(0.12)
                                  : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selectedTab == tab.tag ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct TabItem {
    let icon: String
    let title: String
    let tag: Int
}
