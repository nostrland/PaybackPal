import SwiftUI

struct ActivityView: View {
    @ObservedObject var repository: PaymentsRepository

    var body: some View {
        List(repository.debtData.events.sorted(by: { $0.date > $1.date })) { event in
            VStack(alignment: .leading, spacing: 4) {
                Text(title(for: event.action))
                    .font(.headline)
                Text(event.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(dateString(event.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Activity")
    }

    private func title(for action: AuditAction) -> String {
        switch action {
        case .addPayment: return "Payment Added"
        case .deletePayment: return "Payment Deleted"
        case .updatePaycheckAmount: return "Paycheck Amount Updated"
        }
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ActivityView(repository: .shared)
    }
}
