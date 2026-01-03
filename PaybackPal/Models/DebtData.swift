import Foundation

struct DebtData: Codable {
    var originalAmount: Decimal
    var payments: [Payment]
    var paycheckPaymentAmount: Decimal
    var events: [AuditEvent] = []

    enum CodingKeys: String, CodingKey {
        case originalAmount
        case payments
        case paycheckPaymentAmount
    }

    var currentBalance: Decimal {
        let totalPaid = payments.reduce(Decimal(0)) { partial, payment in
            partial + max(Decimal(0), payment.amount)
        }
        return max(Decimal(0), originalAmount - totalPaid)
    }

    var isPaidOff: Bool {
        currentBalance == 0
    }

    init(
        originalAmount: Decimal = 5055.00,
        payments: [Payment] = [],
        paycheckPaymentAmount: Decimal = 0,
        events: [AuditEvent] = []
    ) {
        self.originalAmount = originalAmount
        self.payments = payments
        self.paycheckPaymentAmount = paycheckPaymentAmount
        self.events = events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        originalAmount = try container.decode(Decimal.self, forKey: .originalAmount)
        payments = try container.decode([Payment].self, forKey: .payments)
        paycheckPaymentAmount = try container.decode(Decimal.self, forKey: .paycheckPaymentAmount)
        events = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(originalAmount, forKey: .originalAmount)
        try container.encode(payments, forKey: .payments)
        try container.encode(paycheckPaymentAmount, forKey: .paycheckPaymentAmount)
    }
}
