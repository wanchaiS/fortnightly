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
    func timeTowardWorkLimit(asOf now: Date) -> DateInterval? {
        let start: Date
        let finish: Date
        switch status {
        case .notWorked:
            return nil
        case .rostered:
            start = rosteredStart
            finish = rosteredFinish
        case .onShift:
            // Still working: at least until the rostered finish, and until now if they've stayed later.
            guard let clockedInAt else { return nil }
            start = clockedInAt
            finish = Swift.max(rosteredFinish, now, clockedInAt)
        case .worked:
            guard let clockedInAt, let clockedOutAt else { return nil }
            start = clockedInAt
            finish = clockedOutAt
        }
        guard finish > start else { return nil }
        return DateInterval(start: start, end: finish)
    }
}

extension Collection<Shift> {
    /// The first shift that takes up time inside `interval`, with that time.
    func firstClash(with interval: DateInterval, asOf now: Date) -> (shift: Shift, time: DateInterval)? {
        for shift in self {
            guard let taken = shift.timeTowardWorkLimit(asOf: now) else { continue }
            if taken.overlaps(interval) {
                return (shift, taken)
            }
        }
        return nil
    }
}

extension DateInterval {
    /// Touching end to start isn't overlapping (unlike `intersects`): finishing at 5pm and starting elsewhere at 5pm is fine.
    func overlaps(_ other: DateInterval) -> Bool {
        start < other.end && other.start < end
    }
}
