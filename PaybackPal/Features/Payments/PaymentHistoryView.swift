import SwiftUI

struct PaymentHistoryView: View {
    let payments: [Payment]
    let onDelete: (Payment) -> Void

    var body: some View {
        List {
            if payments.isEmpty {
                Section {
                    emptyStateView
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                }
            } else {
                ForEach(payments) { payment in
                    PaymentHistoryRowView(payment: payment)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDelete(payment)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Payment History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No payments yet")
                .font(DesignSystem.Typography.title)
                .foregroundColor(.primary)

            Text("Record your first payment to see it here")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

struct PaymentHistoryRowView: View {
    let payment: Payment

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(CurrencyFormatter.shared.string(from: payment.amount))
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)

                Text(Self.dateFormatter.string(from: payment.date))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}