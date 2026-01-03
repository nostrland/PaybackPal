import Foundation

final class PaymentsRepository: ObservableObject {
    static let shared = PaymentsRepository()
    
    private let userDefaultsKey = "debtData"
    
    @Published var debtData: DebtData {
        didSet {
            save()
        }
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(DebtData.self, from: data) {
            self.debtData = decoded
        } else {
            self.debtData = DebtData()
            save()
        }
    }
    
    func addPayment(_ payment: Payment) {
        debtData.payments.append(payment)
        let message = "Added payment: $\(payment.amount) on \(ISO8601DateFormatter().string(from: payment.date))"
        let event = AuditEvent(kind: .paymentAdded, message: message)
        debtData.events.append(event)
    }
    
    func deletePayment(_ payment: Payment) {
        debtData.payments.removeAll { $0.id == payment.id }
        let message = "Deleted payment: $\(payment.amount) on \(ISO8601DateFormatter().string(from: payment.date))"
        let event = AuditEvent(kind: .paymentRemoved, message: message)
        debtData.events.append(event)
    }
    
    func updatePaycheckPaymentAmount(_ amount: Decimal) {
        debtData.paycheckPaymentAmount = amount
        let message = "Updated paycheck amount to $\(amount)"
        let event = AuditEvent(kind: .balanceAdjusted, message: message)
        debtData.events.append(event)
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(debtData) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
}

