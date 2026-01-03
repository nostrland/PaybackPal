import SwiftUI

struct PaymentEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var repository: PaymentsRepository

    @State private var amountText: String = ""
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("Enter Payment Amount")
                    .font(DesignSystem.Typography.title)
                    .padding(.top, DesignSystem.Spacing.lg)

                TextField("$0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(DesignSystem.Typography.largeBalance)
                    .multilineTextAlignment(.center)
                    .focused($isAmountFocused)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .onAppear { isAmountFocused = true }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { isAmountFocused = false }
                        }
                    }

                Spacer()

                Button {
                    savePayment()
                } label: {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.lg)
                .disabled(parseAmount() <= 0)
            }
            .navigationTitle("Custom Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func parseAmount() -> Decimal {
        // Keep it simple and predictable for US-style input
        let cleaned = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")

        let amount = Decimal(string: cleaned) ?? 0
        // Cap at reasonable maximum to prevent overflow and UI issues
        let maxAmount = Decimal(999_999_999)
        return min(max(amount, 0), maxAmount)
    }

    private func savePayment() {
        let amount = parseAmount()
        guard amount > 0 else { return }

        let payment = Payment(amount: amount)
        repository.addPayment(payment)
        dismiss()
    }
}