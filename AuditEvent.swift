import Foundation

enum AuditAction: String, Codable {
    case addPayment
    case deletePayment
    case updatePaycheckAmount
}

struct AuditEvent: Identifiable, Codable {
    let id: UUID
    let date: Date
    let action: AuditAction
    let details: String

    init(id: UUID = UUID(), date: Date = Date(), action: AuditAction, details: String) {
        self.id = id
        self.date = date
        self.action = action
        self.details = details
    }
}
