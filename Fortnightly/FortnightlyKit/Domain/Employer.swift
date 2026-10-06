import Foundation

public enum PayCycle: String, Sendable, CaseIterable {
    case weekly
    case fortnightly
    case monthly
}

/// A business the student works for.
public struct Employer: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var payCycle: PayCycle
    /// Any known pay-period start date; later pay periods are counted from it.
    public var payCycleStartsOn: Date
    /// Employers holding recorded hours are archived, never deleted.
    public var isArchived: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        payCycle: PayCycle = .fortnightly,
        payCycleStartsOn: Date,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.payCycle = payCycle
        self.payCycleStartsOn = payCycleStartsOn
        self.isArchived = isArchived
    }
}
