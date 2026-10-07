import Foundation

public enum ReviewShiftError: Error, Equatable {
    case shiftNotFound
    case recordsUnavailable
}

extension ReviewShiftError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .shiftNotFound: "This shift is no longer on your roster."
        case .recordsUnavailable: "This shift couldn't be loaded right now."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .shiftNotFound: "Open Fortnightly to check your upcoming shifts."
        case .recordsUnavailable: "Open Fortnightly to clock in or out."
        }
    }
}

/// One shift with its employer, as the expanded shift prompt shows it.
public struct ReviewShift: Sendable {
    private let shifts: any ShiftRepository
    private let employers: any EmployerRepository

    public init(shifts: any ShiftRepository, employers: any EmployerRepository) {
        self.shifts = shifts
        self.employers = employers
    }

    public func execute(shiftID: Shift.ID) throws(ReviewShiftError) -> ShiftListing {
        let shift: Shift?
        let employer: Employer?
        do {
            shift = try shifts.shift(withID: shiftID)
            employer = try shift.flatMap { try employers.employer(withID: $0.employerID) }
        } catch {
            throw .recordsUnavailable
        }
        guard let shift else { throw .shiftNotFound }
        return ShiftListing(shift: shift, employer: employer)
    }
}
