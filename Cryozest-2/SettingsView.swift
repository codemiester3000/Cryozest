import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showHabitSelection = false

    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SelectedTherapy.therapyType, ascending: true)]
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Notifications Section
                        notificationsSection

                        // Habits Section
                        habitsSection

                        // About Section
                        aboutSection

                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .sheet(isPresented: $showHabitSelection) {
            TherapyTypeSelectionView()
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        SettingsSection(title: "Notifications", icon: "bell.fill", color: .orange) {
            if !notificationManager.isAuthorized {
                Button(action: {
                    notificationManager.requestAuthorization()
                }) {
                    HStack {
                        Text("Enable Notifications")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.cyan)
                    }
                }
            } else {
                // Daily Reminder
                VStack(spacing: 12) {
                    SettingsToggle(
                        title: "Daily Reminder",
                        subtitle: "Check in and log habits",
                        isOn: $notificationManager.dailyReminderEnabled,
                        onChange: { enabled in
                            if enabled {
                                notificationManager.scheduleDailyReminder()
                            } else {
                                UNUserNotificationCenter.current()
                                    .removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
                            }
                        }
                    )

                    if notificationManager.dailyReminderEnabled {
                        HStack {
                            Text("Time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            DatePicker("", selection: $notificationManager.dailyReminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .scaleEffect(0.9)
                        }
                        .padding(.leading, 4)
                    }

                    divider

                    // Streak Protection
                    SettingsToggle(
                        title: "Streak Protection",
                        subtitle: "Remind at 6pm if habits unlogged",
                        isOn: $notificationManager.streakProtectionEnabled,
                        onChange: { enabled in
                            if !enabled {
                                UNUserNotificationCenter.current()
                                    .removePendingNotificationRequests(withIdentifiers: ["streak-protection"])
                            }
                        }
                    )

                    divider

                    // Weekly Digest
                    SettingsToggle(
                        title: "Weekly Digest",
                        subtitle: "Insights summary every Sunday",
                        isOn: $notificationManager.weeklyDigestEnabled,
                        onChange: { enabled in
                            if enabled {
                                notificationManager.scheduleWeeklyDigest()
                            } else {
                                UNUserNotificationCenter.current()
                                    .removePendingNotificationRequests(withIdentifiers: ["weekly-digest"])
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Habits Section

    private var habitsSection: some View {
        SettingsSection(title: "Habits", icon: "checkmark.circle.fill", color: .green) {
            VStack(spacing: 12) {
                HStack {
                    Text("Active Habits")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(selectedTherapies.count)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.cyan)
                }

                // Show current habits as chips
                if !selectedTherapies.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(selectedTherapies, id: \.self) { therapy in
                            if let rawValue = therapy.therapyType,
                               let type = TherapyType(rawValue: rawValue) {
                                HabitChip(type: type)
                            }
                        }
                    }
                }

                Button(action: { showHabitSelection = true }) {
                    HStack {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Edit Habits")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.cyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cyan.opacity(0.12))
                    )
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle.fill", color: .cyan) {
            VStack(spacing: 12) {
                aboutRow(label: "Version", value: appVersion)
                divider
                aboutRow(label: "Build", value: buildNumber)
                divider

                Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                    HStack {
                        Text("Privacy Policy")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Settings Section Container

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: () -> Content

    init(title: String, icon: String, color: Color, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Settings Toggle

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var onChange: ((Bool) -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.cyan)
                .onChange(of: isOn) { newValue in
                    onChange?(newValue)
                }
        }
    }
}

// MARK: - Habit Chip

struct HabitChip: View {
    let type: TherapyType
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(type.color)

            Text(type.displayName(viewContext))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(type.color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(type.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
