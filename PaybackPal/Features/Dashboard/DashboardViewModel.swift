import Foundation
import SwiftUI
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Dependencies

    let repository: PaymentsRepository
    let reminderScheduler: ReminderScheduler

    // MARK: - View State

    @Published private(set) var debtData: DebtData

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Derived UI State

    var currentBalance: Decimal {
        debtData.currentBalance
    }

    var recentPayments: [Payment] {
        debtData.payments.sorted { $0.date > $1.date }
    }

    var estimatedPayoffDate: Date? {
        let balance = currentBalance
        let biweeklyPayment = debtData.paycheckPaymentAmount

        guard biweeklyPayment > 0 else { return nil }

        let nextPayday = DateHelpers.nextPayday()
        return DateHelpers.estimatePayoffDate(
            balance: balance,
            biweeklyPayment: biweeklyPayment,
            startDate: nextPayday
        )
    }

    // Reminder UI state exposed cleanly to the View
    var hasNotificationPermission: Bool {
        reminderScheduler.hasPermission
    }

    var remindersScheduled: Bool {
        reminderScheduler.remindersScheduled
    }

    // MARK: - Init

    init(
        repository: PaymentsRepository,
        reminderScheduler: ReminderScheduler
    ) {
        self.repository = repository
        self.reminderScheduler = reminderScheduler
        self.debtData = repository.debtData

        // Keep ViewModel state in sync with repository changes
        repository.$debtData
            .sink { [weak self] newData in
                self?.debtData = newData
            }
            .store(in: &cancellables)

        // Forward ReminderScheduler changes so the Dashboard UI refreshes
        reminderScheduler.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    @MainActor
    convenience init() {
        self.init(
            repository: .shared,
            reminderScheduler: .shared
        )
    }

    // MARK: - Payments

    func addQuickPayment(_ amount: Decimal) {
        let payment = Payment(amount: amount)
        repository.addPayment(payment)
    }

    func deletePayment(_ payment: Payment) {
        repository.deletePayment(payment)
    }

    func updatePaycheckAmount(_ amount: Decimal) {
        repository.updatePaycheckPaymentAmount(amount)
    }

    // MARK: - Notifications

    func requestNotificationPermission() {
        Task {
            await reminderScheduler.requestPermission()
        }
    }

    func scheduleReminders() {
        Task {
            await reminderScheduler.scheduleBiweeklyReminders()
        }
    }

    func clearReminders() {
        Task {
            await reminderScheduler.clearScheduledPaydayReminders()
        }
    }
}
