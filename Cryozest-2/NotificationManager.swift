import Foundation
import UserNotifications
import CoreData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var dailyReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(dailyReminderEnabled, forKey: "dailyReminderEnabled") }
    }
    @Published var streakProtectionEnabled: Bool {
        didSet { UserDefaults.standard.set(streakProtectionEnabled, forKey: "streakProtectionEnabled") }
    }
    @Published var weeklyDigestEnabled: Bool {
        didSet { UserDefaults.standard.set(weeklyDigestEnabled, forKey: "weeklyDigestEnabled") }
    }
    @Published var dailyReminderTime: Date {
        didSet {
            UserDefaults.standard.set(dailyReminderTime, forKey: "dailyReminderTime")
            if dailyReminderEnabled { scheduleDailyReminder() }
        }
    }

    private let center = UNUserNotificationCenter.current()

    private init() {
        self.dailyReminderEnabled = UserDefaults.standard.bool(forKey: "dailyReminderEnabled")
        self.streakProtectionEnabled = UserDefaults.standard.bool(forKey: "streakProtectionEnabled")
        self.weeklyDigestEnabled = UserDefaults.standard.bool(forKey: "weeklyDigestEnabled")

        if let saved = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Date {
            self.dailyReminderTime = saved
        } else {
            // Default: 8pm
            var components = DateComponents()
            components.hour = 20
            components.minute = 0
            self.dailyReminderTime = Calendar.current.date(from: components) ?? Date()
        }

        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.scheduleAll()
                }
                completion(granted)
            }
        }
    }

    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule All

    func scheduleAll() {
        if dailyReminderEnabled { scheduleDailyReminder() }
        if weeklyDigestEnabled { scheduleWeeklyDigest() }
        // Streak protection is scheduled dynamically
    }

    // MARK: - Daily Reminder

    func scheduleDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])

        guard dailyReminderEnabled, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "How are you feeling today?"
        content.body = "Take 10 seconds to check in and log your habits."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: dailyReminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Streak Protection

    func scheduleStreakProtection(unloggedHabits: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ["streak-protection"])

        guard streakProtectionEnabled, isAuthorized, !unloggedHabits.isEmpty else { return }

        let content = UNMutableNotificationContent()

        if unloggedHabits.count == 1 {
            content.title = "Keep your streak alive!"
            content.body = "You haven't logged \(unloggedHabits[0]) today."
        } else {
            content.title = "Keep your streaks alive!"
            content.body = "You have \(unloggedHabits.count) habits to log today."
        }
        content.sound = .default

        // Fire at 6pm today
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "streak-protection", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Weekly Digest

    func scheduleWeeklyDigest() {
        center.removePendingNotificationRequests(withIdentifiers: ["weekly-digest"])

        guard weeklyDigestEnabled, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your Weekly Insights"
        content.body = "See what worked this week. Tap to view your trends."
        content.sound = .default

        // Sunday 9am
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-digest", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Cancel All

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Streak Check

    func checkAndScheduleStreakProtection(sessions: [TherapySessionEntity], selectedHabitNames: [String]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let loggedToday = Set(
            sessions
                .filter { session in
                    guard let date = session.date else { return false }
                    return calendar.isDate(date, inSameDayAs: today)
                }
                .compactMap { $0.therapyType }
        )

        let unlogged = selectedHabitNames.filter { !loggedToday.contains($0) }

        if !unlogged.isEmpty {
            let displayNames = unlogged.compactMap { rawValue in
                TherapyType(rawValue: rawValue)?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
            }
            scheduleStreakProtection(unloggedHabits: displayNames)
        }
    }
}
