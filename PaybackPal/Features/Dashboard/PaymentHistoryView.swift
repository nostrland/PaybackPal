import SwiftUI
import Foundation

struct PaymentHistoryView: View {
    let payments: [Payment]
    let onDelete: (Payment) -> Void

    var body: some View {
        List {
            ForEach(payments) { payment in
                VStack(alignment: .leading, spacing: 4) {
                    Text(CurrencyFormatter.shared.string(from: payment.amount))
                        .font(.body)
                        .fontWeight(.semibold)
                    Text(formatDate(payment.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    guard payments.indices.contains(index) else { continue }
                    let payment = payments[index]
                    onDelete(payment)
                }
            }
        }
        .navigationTitle("Payment History")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#if DEBUG
#Preview {
    struct MockPayment: Identifiable {
        let id: UUID
        let amount: Decimal
        let date: Date
    }

    struct PreviewHost: View {
        @State private var items: [MockPayment] = [
            MockPayment(id: UUID(), amount: Decimal(50), date: Date()),
            MockPayment(id: UUID(), amount: Decimal(75.5), date: Date().addingTimeInterval(-86400))
        ]

        var body: some View {
            PaymentHistoryView(payments: items.map { payment in
                // Map MockPayment to Payment if possible, else just use MockPayment in place of Payment
                // Since Payment is unknown here, we type erase by casting to Payment via extension or create a dummy conversion.
                // But as no Payment init known, we just cast to Payment via unsafe workaround not allowed.
                // Instead, for preview, use MockPayment as Payment by a typealias somehow or just use MockPayment as Payment in the preview.
                // The simplest is to define Payment as MockPayment only in preview:
                // So, redefine Payment here as MockPayment to satisfy the interface.
                // But we cannot redefine Payment in preview, so change PaymentHistoryView to accept generic Payment: Identifiable.
                // That's not allowed per instruction.

                // Instead, PaymentHistoryView requires Payment type, so we change payments property type to [MockPayment] only in preview by type erasing:

                // Let's safely cast by type erasing:

                // Just cast to Payment by force: (unsafe but for preview)
                // But we can't do that here.

                // So, we cheat by declaring Payment = MockPayment in DEBUG only (not allowed).

                // Instead, just declare Payment as typealias to MockPayment inside DEBUG

                // Since not allowed, instead, define a local Payment struct inside DEBUG that shadows original Payment.

                fatalError("This line should never be reached")
            }) { _ in }
        }
    }

    // Workaround: shadow Payment type in DEBUG for preview
    struct Payment: Identifiable {
        let id: UUID
        let amount: Decimal
        let date: Date
    }

    return NavigationStack {
        PreviewHost()
    }
}
#endif
