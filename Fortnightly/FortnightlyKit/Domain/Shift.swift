import Foundation

public enum ShiftStatus: String, Sendable {
    /// Planned by the employer; not yet clocked in.
    case rostered
    /// Clocked in, not yet clocked out.
    case onShift
    /// Clocked in and out.
    case worked
    /// Rostered but didn't happen (cancelled or swapped).
    case notWorked
}

/// One block of work for one employer: what was rostered, and what was actually worked.
public struct Shift: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let employerID: Employer.ID
    public var rosteredStart: Date
    public var rosteredFinish: Date
    public var clockedInAt: Date?
    public var clockedOutAt: Date?
    public var status: ShiftStatus
    public var note: String?

    public init(
        id: UUID = UUID(),
        employerID: Employer.ID,
        rosteredStart: Date,
        rosteredFinish: Date,
        clockedInAt: Date? = nil,
        clockedOutAt: Date? = nil,
        status: ShiftStatus = .rostered,
        note: String? = nil
    ) {
        self.id = id
        self.employerID = employerID
        self.rosteredStart = rosteredStart
        self.rosteredFinish = rosteredFinish
        self.clockedInAt = clockedInAt
        self.clockedOutAt = clockedOutAt
        self.status = status
        self.note = note
    }
}

extension Shift {
    /// The time this shift counts toward the work limit: actual times once clocked in,
    /// rostered times until then, nothing if it wasn't worked.
    var timeTowardWorkLimit: DateInterval? {
        let start: Date
        let finish: Date
        switch status {
        case .notWorked:
            return nil
        case .rostered:
            start = rosteredStart
            finish = rosteredFinish
        case .onShift:
            // Still working: assume the rostered finish until they clock out.
            guard let clockedInAt else { return nil }
            start = clockedInAt
            finish = Swift.max(rosteredFinish, clockedInAt)
        case .worked:
            guard let clockedInAt, let clockedOutAt else { return nil }
            start = clockedInAt
            finish = clockedOutAt
        }
        guard finish > start else { return nil }
        return DateInterval(start: start, end: finish)
    }
}
