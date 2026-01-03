import Foundation

/// Represents an audit trail event for actions taken on a debt record.
/// Not persisted as part of DebtData's Codable payload (DebtData omits `events` in CodingKeys).
public struct AuditEvent: Codable, Identifiable, Equatable {
    public enum Kind: String, Codable {
        case created
        case paymentAdded
        case paymentRemoved
        case balanceAdjusted
        case note
    }

    /// Unique identifier for the event
    public let id: UUID
    /// Timestamp of when the event occurred
    public let date: Date
    /// The kind/category of event
    public let kind: Kind
    /// Optional human-readable description
    public var message: String?

    public init(id: UUID = UUID(), date: Date = Date(), kind: Kind, message: String? = nil) {
        self.id = id
        self.date = date
        self.kind = kind
        self.message = message
    }
}
