import SwiftUI

extension Color {
    static let customOrange = Color(red: 255 / 255, green: 140 / 255, blue: 0 / 255)
    static let appleLimeGreen = Color(red: 50.0 / 255, green: 205 / 255, blue: 50 / 255)
}

struct AppTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var sessions: [TherapySession] = []
    @StateObject private var therapyTypeSelection = TherapyTypeSelection()
    
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DailyView(
                recoveryModel: RecoveryGraphModel(selectedDate: Date()),
                exertionModel: ExertionModel(selectedDate: Date()),
                sleepModel: DailySleepViewModel(selectedDate: Date()),
                context: viewContext)
                .tabItem {
                    Image(systemName: "moon.fill")
                    Text("Daily")
                }
                .tag(0)
                .toolbarBackground(Color(red: 0.08, green: 0.18, blue: 0.28).opacity(0.95), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)

            MainView(therapyTypeSelection: therapyTypeSelection)
                .tabItem {
                    Image(systemName: "stopwatch.fill")
                    Text("Habits")
                }
                .tag(1)
                .toolbarBackground(Color(red: 0.08, green: 0.18, blue: 0.28).opacity(0.95), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)

            AnalysisView(therapyTypeSelection: therapyTypeSelection, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analysis")
                }
                .tag(2)
                .toolbarBackground(Color(red: 0.08, green: 0.18, blue: 0.28).opacity(0.95), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
        .accentColor(.cyan)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(red: 0.08, green: 0.18, blue: 0.28).opacity(0.95))

            // Unselected items - white with opacity
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.5),
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]

            // Selected items - cyan
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0, green: 1, blue: 1, alpha: 1)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0, green: 1, blue: 1, alpha: 1),
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
