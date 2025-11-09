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
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)

            MainView(therapyTypeSelection: therapyTypeSelection)
                .tabItem {
                    Image(systemName: "stopwatch.fill")
                    Text("Habits")
                }
                .tag(1)
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)

            InsightsView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Image(systemName: "lightbulb.fill")
                    Text("Insights")
                }
                .tag(2)
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
        .accentColor(.cyan)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()

            // Glassmorphism effect - darker translucent background for better readability
            appearance.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.10, alpha: 0.85)

            // Enable blur effect for glassmorphism
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)

            // Remove default shadow, we'll add our own
            appearance.shadowColor = nil
            appearance.shadowImage = UIImage()

            // Unselected items - improved readability with higher opacity
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.65)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.65),
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
            ]

            // Selected items - brighter, more vibrant cyan for better contrast
            let selectedColor = UIColor(red: 0.4, green: 0.9, blue: 1.0, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: selectedColor,
                .font: UIFont.systemFont(ofSize: 11, weight: .bold)
            ]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance

            // Add floating effect with custom layer modifications
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                    let tabBar = tabBarController.tabBar

                    // Add corner radius for floating effect
                    tabBar.layer.cornerRadius = 24
                    tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    tabBar.layer.masksToBounds = true

                    // Add shadow for depth
                    tabBar.layer.shadowColor = UIColor.black.cgColor
                    tabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
                    tabBar.layer.shadowOpacity = 0.25
                    tabBar.layer.shadowRadius = 12
                    tabBar.layer.masksToBounds = false

                    // Add subtle border on top for glassmorphism
                    let borderLayer = CALayer()
                    borderLayer.backgroundColor = UIColor.white.withAlphaComponent(0.1).cgColor
                    borderLayer.frame = CGRect(x: 0, y: 0, width: tabBar.bounds.width, height: 0.5)
                    tabBar.layer.addSublayer(borderLayer)
                }
            }
        }
    }
}
