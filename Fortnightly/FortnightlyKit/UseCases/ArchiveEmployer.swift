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

    public func execute(employerID: Employer.ID) throws(ArchiveEmployerError) {
        // TDD red: not implemented yet.
    }
}
