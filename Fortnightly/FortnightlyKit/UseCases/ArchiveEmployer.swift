import Foundation

public enum ArchiveEmployerError: Error, Equatable {
    case employerNotFound
    case stillOnShift
    case hasUpcomingShifts(count: Int)
    case recordsUnavailable
}

extension ArchiveEmployerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .employerNotFound:
            "This employer is no longer in your list."
        case .stillOnShift:
            "You're still clocked in at this employer."
        case let .hasUpcomingShifts(count):
            count == 1 ? "You still have 1 upcoming shift here." : "You still have \(count) upcoming shifts here."
        case .recordsUnavailable:
            "This change couldn't be saved."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .employerNotFound:
            "Check your employers in Jobs."
        case .stillOnShift:
            "Clock out first, then archive them."
        case .hasUpcomingShifts:
            "Mark those shifts as not working first, so nothing is cancelled without you knowing. Then archive them."
        case .recordsUnavailable:
            "Your shifts are safe. Try again."
        }
    }
}

/// The student no longer works somewhere. The employer leaves the lists, but every hour worked there keeps counting.
public struct ArchiveEmployer: Sendable {
    private let employers: any EmployerRepository
    private let shifts: any ShiftRepository
    private let display: any ShiftDisplayRefreshing
    private let now: @Sendable () -> Date

    public init(
        employers: any EmployerRepository,
        shifts: any ShiftRepository,
        display: any ShiftDisplayRefreshing,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.employers = employers
        self.shifts = shifts
        self.display = display
        self.now = now
    }

    /// Refused while the student is on shift there or has upcoming shifts there: nothing is cancelled silently.
    /// No shift is touched, so hours already worked keep counting toward the limit.
    public func execute(employerID: Employer.ID) throws(ArchiveEmployerError) {
        guard var employer = try read({ try employers.employer(withID: employerID) }) else { throw .employerNotFound }
        guard employer.isArchived == false else { return }
        if let openShift = try read({ try shifts.openShift() }), openShift.employerID == employerID {
            throw .stillOnShift
        }
        let upcoming = try read { try shifts.upcomingShifts(after: now()) }.filter { $0.employerID == employerID }
        guard upcoming.isEmpty else { throw .hasUpcomingShifts(count: upcoming.count) }

        employer.isArchived = true
        try read { try employers.save(employer) }
        display.shiftsDidChange()
    }

    private func read<Value>(_ operation: () throws -> Value) throws(ArchiveEmployerError) -> Value {
        do {
            return try operation()
        } catch {
            throw .recordsUnavailable
        }
    }
}
