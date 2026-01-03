import Foundation
import UserNotifications

@MainActor
final class ReminderScheduler: ObservableObject {
    static let shared = ReminderScheduler()

    @Published private(set) var hasPermission: Bool = false
    @Published private(set) var remindersScheduled: Bool = false
    @Published var anchorPayday: Date? {
        didSet {
            if let date = anchorPayday {
                UserDefaults.standard.set(date, forKey: "anchorPayday")
            } else {
                UserDefaults.standard.removeObject(forKey: "anchorPayday")
            }
        }
    }

    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderIdPrefix = "payday-reminder-"

    private init() {
        // Load stored anchor date
        if let stored = UserDefaults.standard.object(forKey: "anchorPayday") as? Date {
            self.anchorPayday = stored
        }
        
        Task {
            await refreshStatus()
        }
    }

    func requestPermission() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            // Even if granted is false, refresh the real settings state
            await refreshStatus()
            if !granted {
                // Keep it quiet for v1; UI can show status
            }
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }

    /// Schedules the next 6 biweekly Wednesday reminders at 9:00 AM local time.
    /// This function checks permission status at runtime so it is reliable even if
    /// the UI state is slightly behind.
    func scheduleBiweeklyReminders() async {
        let settings = await notificationCenter.notificationSettings()
        let authorized = settings.authorizationStatus == .authorized ||
                         settings.authorizationStatus == .provisional ||
                         settings.authorizationStatus == .ephemeral

        hasPermission = authorized
        guard authorized else {
            remindersScheduled = false
            return
        }

        // Remove only our existing payday reminders before re-scheduling
        await clearScheduledPaydayReminders()

        let paydays = DateHelpers.nextPaydays(count: 6)

        for (index, payday) in paydays.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Payback time"
            content.body = "Payday reminder: make a payment and update the balance."
            content.sound = .default

            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: payday)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let request = UNNotificationRequest(
                identifier: "\(reminderIdPrefix)\(index)",
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling notification: \(error)")
            }
        }

        await refreshStatus()
    }

    /// Schedules reminders based on a specific anchor date (first payday).
    /// Schedules the next 6 occurrences from the anchor date at 9:00 AM.
    func scheduleRemindersWithAnchor(anchorDate: Date) async {
        // Request permission first if needed
        let settings = await notificationCenter.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            await requestPermission()
        }
        
        let authorized = settings.authorizationStatus == .authorized ||
                         settings.authorizationStatus == .provisional ||
                         settings.authorizationStatus == .ephemeral
        
        hasPermission = authorized
        guard authorized else {
            remindersScheduled = false
            return
        }
        
        // Store the anchor date
        self.anchorPayday = anchorDate
        
        // Clear existing reminders
        await clearScheduledPaydayReminders()
        
        // Calculate next 6 paydays from anchor
        let paydays = calculatePaydaysFromAnchor(anchorDate: anchorDate, count: 6)
        
        for (index, payday) in paydays.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Payback time"
            content.body = "Payday reminder: make a payment and update the balance."
            content.sound = .default
            
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: payday)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "\(reminderIdPrefix)\(index)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling notification: \(error)")
            }
        }
        
        await refreshStatus()
    }
    
    /// Clears only reminders created by this scheduler (matching the prefix).
    func clearScheduledPaydayReminders() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let idsToRemove = requests
            .map { $0.identifier }
            .filter { $0.hasPrefix(reminderIdPrefix) }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        
        // Clear anchor date when clearing reminders
        anchorPayday = nil
        
        await refreshStatus()
    }
    
    /// Calculate next N paydays from anchor date (biweekly, 14 days apart).
    /// Only returns future dates from now.
    private func calculatePaydaysFromAnchor(anchorDate: Date, count: Int) -> [Date] {
        guard count > 0 else { return [] }
        
        let now = Date()
        var paydays: [Date] = []
        var currentDate = anchorDate
        
        // Find the first future occurrence
        while currentDate <= now {
            currentDate = Calendar.current.date(byAdding: .day, value: 14, to: currentDate) ?? currentDate
        }
        
        // Collect next N occurrences
        for _ in 0..<count {
            paydays.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 14, to: currentDate) ?? currentDate
        }
        
        return paydays
    }

    /// Updates hasPermission + remindersScheduled from system state.
    func refreshStatus() async {
        let settings = await notificationCenter.notificationSettings()
        hasPermission = settings.authorizationStatus == .authorized ||
                        settings.authorizationStatus == .provisional ||
                        settings.authorizationStatus == .ephemeral

        let requests = await notificationCenter.pendingNotificationRequests()
        remindersScheduled = requests.contains { $0.identifier.hasPrefix(reminderIdPrefix) }
    }
}

private extension UNUserNotificationCenter {
    func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { (continuation: CheckedContinuation<UNNotificationSettings, Never>) in
            getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[UNNotificationRequest], Never>) in
            getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            add(request) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
