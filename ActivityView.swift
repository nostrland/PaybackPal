import SwiftUI

struct ActivityView: View {
    @ObservedObject var repository: PaymentsRepository
    @State private var isSharing = false
    @State private var shareItems: [Any] = []

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    exportActivity()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $isSharing) {
            ShareSheet(activityItems: shareItems)
        }
    }

    private func exportActivity() {
        let events = repository.debtData.events
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(events)
            let filename = "Activity_\(Date().ISO8601Format()).json"
            let url = temporaryFileURL(fileName: filename)
            try data.write(to: url, options: .atomic)
            shareItems = [url]
            isSharing = true
        } catch {
            // Fallback to sharing plain text if JSON file fails for any reason
            let fallback = events.map { "\($0.date): \($0.action.rawValue) - \($0.details)" }.joined(separator: "\n")
            shareItems = [fallback]
            isSharing = true
        }
    }

    private func temporaryFileURL(fileName: String) -> URL {
        let directory = FileManager.default.temporaryDirectory
        return directory.appendingPathComponent(fileName)
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

// MARK: - Share Sheet Wrapper

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ActivityView(repository: .shared)
    }
}
