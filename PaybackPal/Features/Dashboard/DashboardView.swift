import SwiftUI
import Foundation

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showPaymentEntry = false
    @State private var lastDeletedPayment: Payment? = nil
    @State private var showUndoBanner = false
    @State private var undoHideWorkItem: DispatchWorkItem? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {

                    // MARK: - Balance Section
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Text("Owed Balance")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.secondary)

                        Text(CurrencyFormatter.shared.string(from: viewModel.currentBalance))
                            .font(DesignSystem.Typography.largeBalance)
                            .foregroundColor(.primary)

                        if let payoffDate = viewModel.estimatedPayoffDate {
                            Text("Estimated payoff: \(formatPayoffDate(payoffDate))")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, DesignSystem.Spacing.sm)
                        } else {
                            Text("No payoff estimate")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, DesignSystem.Spacing.sm)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.xl)

                    // MARK: - Quick Payment Buttons
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Text("Quick Payment")
                            .font(DesignSystem.Typography.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                        HStack(spacing: DesignSystem.Spacing.md) {
                            QuickPaymentButton(amount: 20) {
                                viewModel.addQuickPayment(20)
                            }
                            QuickPaymentButton(amount: 50) {
                                viewModel.addQuickPayment(50)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)

                        HStack(spacing: DesignSystem.Spacing.md) {
                            QuickPaymentButton(amount: 100) {
                                viewModel.addQuickPayment(100)
                            }
                            QuickPaymentButton(amount: 200) {
                                viewModel.addQuickPayment(200)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)

                        Button {
                            showPaymentEntry = true
                        } label: {
                            Text("Custom…")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.md)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }

                    // MARK: - Paycheck Slider
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Text("Payment amount")
                            .font(DesignSystem.Typography.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                        VStack(spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("$0")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(
                                    CurrencyFormatter.shared.string(
                                        from: viewModel.debtData.paycheckPaymentAmount
                                    )
                                )
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.semibold)

                                Spacer()

                                Text("$500")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                            Slider(
                                value: Binding(
                                    get: {
                                        NSDecimalNumber(
                                            decimal: viewModel.debtData.paycheckPaymentAmount
                                        ).doubleValue
                                    },
                                    set: {
                                        viewModel.updatePaycheckAmount(Decimal($0))
                                    }
                                ),
                                in: 0...500,
                                step: 10
                            )
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                            if viewModel.debtData.paycheckPaymentAmount == 0 {
                                Text("Bump this up to finish sooner")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                            }
                        }
                    }

                    // MARK: - Reminders Section
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Text("Reminders")
                            .font(DesignSystem.Typography.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                        if !viewModel.hasNotificationPermission {
                            Button {
                                viewModel.requestNotificationPermission()
                            } label: {
                                Text("Enable Notifications")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignSystem.Spacing.md)
                                    .background(DesignSystem.Colors.primary)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        } else {
                            Button {
                                viewModel.scheduleReminders()
                            } label: {
                                Text("Schedule biweekly payday reminder")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignSystem.Spacing.md)
                                    .background(DesignSystem.Colors.primary)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                            Button {
                                viewModel.clearReminders()
                            } label: {
                                Text("Clear scheduled reminders")
                                    .font(.headline)
                                    .foregroundColor(DesignSystem.Colors.danger)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignSystem.Spacing.md)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }

                        Text(
                            "Reminders scheduled: \(viewModel.remindersScheduled ? "Yes" : "No")"
                        )
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }

                    // MARK: - Recent Payments
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Text("Recent Payments")
                            .font(DesignSystem.Typography.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                        if viewModel.recentPayments.isEmpty {
                            Text("No payments yet")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, DesignSystem.Spacing.lg)
                        } else {
                            ForEach(viewModel.recentPayments) { payment in
                                PaymentRowView(payment: payment) {
                                    lastDeletedPayment = payment
                                    showUndoBanner = true
                                    scheduleUndoAutoHide()
                                    viewModel.deletePayment(payment)
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
            .navigationTitle("PaybackPal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        PaymentHistoryView(
                            payments: viewModel.recentPayments,
                            payoffEstimate: computePayoffEstimateDate(
                                balance: viewModel.currentBalance,
                                payments: viewModel.recentPayments
                            ),
                            onDelete: { payment in
                                lastDeletedPayment = payment
                                showUndoBanner = true
                                scheduleUndoAutoHide()
                                viewModel.deletePayment(payment)
                            }
                        )
                    } label: {
                        Label("History", systemImage: "clock")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showPaymentEntry) {
                PaymentEntryView(repository: viewModel.repository)
            }
            .overlay(alignment: .bottom) {
                if showUndoBanner, let last = lastDeletedPayment {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Text("Payment deleted")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            // Re-add the last deleted amount as a new payment
                            viewModel.addQuickPayment(last.amount)
                            lastDeletedPayment = nil
                            showUndoBanner = false
                            undoHideWorkItem?.cancel()
                            undoHideWorkItem = nil
                        } label: {
                            Text("Undo")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private func scheduleUndoAutoHide() {
        undoHideWorkItem?.cancel()
        let work = DispatchWorkItem {
            withAnimation {
                showUndoBanner = false
            }
            lastDeletedPayment = nil
        }
        undoHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
    }

    private func formatPayoffDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func computePayoffEstimateDate(balance: Decimal, payments: [Payment]) -> Date? {
        // Require a positive balance and at least one payment
        guard balance > 0, !payments.isEmpty else { return nil }

        // Sort payments by date ascending and focus on only the most recent few payments
        let sorted = payments.sorted { $0.date < $1.date }
        let windowSize = 5 // consider the last up to 5 payments
        let recent = Array(sorted.suffix(windowSize))

        // Average payment amount; use absolute values to support negative-recorded payments
        let amounts: [Decimal] = recent.map { payment in
            let amt = payment.amount
            return amt >= 0 ? amt : -amt
        }
        let positiveAmounts = amounts.filter { $0 > 0 }
        guard !positiveAmounts.isEmpty else { return nil }
        let total = positiveAmounts.reduce(Decimal(0), +)
        let count = Decimal(positiveAmounts.count)
        let avgPayment = total / count
        guard avgPayment > 0 else { return nil }

        // Average interval in days between the recent payments; default to 14 days if only one
        let avgIntervalDays: Double
        if recent.count >= 2 {
            var intervals: [TimeInterval] = []
            for i in 1..<recent.count {
                intervals.append(recent[i].date.timeIntervalSince(recent[i - 1].date))
            }
            let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
            // Convert seconds to days; clamp to at least 1 day
            avgIntervalDays = max(avgInterval / 86_400.0, 1.0)
        } else {
            avgIntervalDays = 14.0
        }

        // Compute number of periods needed (ceil to whole periods)
        let remaining = NSDecimalNumber(decimal: balance).doubleValue
        let avgPay = NSDecimalNumber(decimal: avgPayment).doubleValue
        guard avgPay > 0 else { return nil }
        let periodsNeeded = ceil(remaining / avgPay)

        // Base date is the most recent payment date if available; otherwise today
        let baseDate = recent.last?.date ?? Date()
        let daysToAdd = periodsNeeded * avgIntervalDays
        return Calendar.current.date(byAdding: .day, value: Int(daysToAdd), to: baseDate)
    }
}

// MARK: - Subviews

struct QuickPaymentButton: View {
    let amount: Decimal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("+\(CurrencyFormatter.shared.string(from: amount))")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(12)
        }
    }
}

struct PaymentRowView: View {
    let payment: Payment
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(CurrencyFormatter.shared.string(from: payment.amount))
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)

                Text(formatDate(payment.date))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

