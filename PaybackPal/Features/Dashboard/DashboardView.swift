import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showPaymentEntry = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {

                    // Balance Section
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

                    // Quick Payment Buttons
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Text("Quick Payment")
                            .font(DesignSystem.Typography.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                        HStack(spacing: DesignSystem.Spacing.md) {
                            QuickPaymentButton(amount: 20) { viewModel.addQuickPayment(20) }
                            QuickPaymentButton(amount: 50) { viewModel.addQuickPayment(50) }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)

                        HStack(spacing: DesignSystem.Spacing.md) {
                            QuickPaymentButton(amount: 100) { viewModel.addQuickPayment(100) }
                            QuickPaymentButton(amount: 200) { viewModel.addQuickPayment(200) }
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

                    // Paycheck Payment Slider
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Text("Paycheck payment amount")
                            .font(DesignSystem.Typography.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                        VStack(spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("$0")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(CurrencyFormatter.shared.string(from: viewModel.debtData.paycheckPaymentAmount))
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
                                    get: { viewModel.debtData.paycheckPaymentAmount.doubleValue },
                                    set: { viewModel.updatePaycheckAmount(Decimal($0)) }
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

                    // Reminders Section
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

                        Text("Reminders scheduled: \(viewModel.remindersScheduled ? "Yes" : "No")")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                    }

                    // Recent Payments
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
                            onDelete: { payment in
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
        }
    }

    private func formatPayoffDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

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