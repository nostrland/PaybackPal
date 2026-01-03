import Foundation

struct Payment: Identifiable, Codable, Equatable {
    let id: UUID
    let amount: Decimal
    let date: Date

    init(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = Date()
    ) {
        self.id = id
        self.amount = max(Decimal(0), amount)
        self.date = date
    }

    static func == (lhs: Payment, rhs: Payment) -> Bool {
        lhs.id == rhs.id && lhs.amount == rhs.amount && lhs.date == rhs.date
    }
}
