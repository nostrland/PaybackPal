import SwiftUI

struct ReminderSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var reminderScheduler: ReminderScheduler
    
    @State private var selectedDate: Date
    @State private var isEnabled: Bool
    
    init(reminderScheduler: ReminderScheduler) {
        self.reminderScheduler = reminderScheduler
        
        // Initialize with stored anchor date or next Wednesday at 9 AM
        let stored = reminderScheduler.anchorPayday ?? DateHelpers.nextPayday()
        _selectedDate = State(initialValue: stored)
        _isEnabled = State(initialValue: reminderScheduler.remindersScheduled)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Payday Reminders")
                            .font(DesignSystem.Typography.title)
                        
                        Text("Get notified every two weeks on your payday to make a payment.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
                
                Section {
                    Toggle("Enable Reminders", isOn: $isEnabled)
                        .font(DesignSystem.Typography.body)
                }
                
                if isEnabled {
                    Section {
                        DatePicker(
                            "First Payday",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        
                        Text("Reminders will repeat every 2 weeks starting from this date at 9:00 AM.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Schedule")
                    }
                    
                    Section {
                        if let nextReminder = nextReminderDate {
                            HStack {
                                Text("Next Reminder")
                                    .font(DesignSystem.Typography.caption)
                                Spacer()
                                Text(formatDate(nextReminder))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reminder Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var nextReminderDate: Date? {
        guard isEnabled else { return nil }
        
        // Set time to 9 AM
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = 9
        components.minute = 0
        components.second = 0
        
        guard let anchorDate = Calendar.current.date(from: components) else { return nil }
        
        // Find next occurrence from now
        let now = Date()
        if anchorDate > now {
            return anchorDate
        }
        
        // Calculate how many periods have passed
        let interval = now.timeIntervalSince(anchorDate)
        let twoWeeksInSeconds: TimeInterval = 14 * 24 * 60 * 60
        let periodsPassed = Int(ceil(interval / twoWeeksInSeconds))
        
        return Calendar.current.date(byAdding: .day, value: periodsPassed * 14, to: anchorDate)
    }
    
    private func saveSettings() {
        Task {
            if isEnabled {
                // Set time to 9 AM
                var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
                components.hour = 9
                components.minute = 0
                components.second = 0
                
                if let anchorDate = Calendar.current.date(from: components) {
                    await reminderScheduler.scheduleRemindersWithAnchor(anchorDate: anchorDate)
                }
            } else {
                await reminderScheduler.clearScheduledPaydayReminders()
            }
            dismiss()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


