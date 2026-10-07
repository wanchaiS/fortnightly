import Foundation

public enum ReviewMissedShiftsError: Error, Equatable {
    case recordsUnavailable
}

extension ReviewMissedShiftsError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .recordsUnavailable: "Your shifts couldn't be checked right now."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .recordsUnavailable: "Your shifts are safe. Close and reopen Fortnightly."
        }
    }
}

/// Shifts that finished without a clock-in. Their rostered hours still count toward the limit
/// until the student says whether they worked them.
public struct ReviewMissedShifts: Sendable {
    private let shifts: any ShiftRepository
    private let employers: any EmployerRepository
    private let now: @Sendable () -> Date

    public init(shifts: any ShiftRepository, employers: any EmployerRepository, now: @escaping @Sendable () -> Date = Date.init) {
        self.shifts = shifts
        self.employers = employers
        self.now = now
    }

    public func execute() throws(ReviewMissedShiftsError) -> [ShiftListing] {
        // TDD red: not implemented yet.
        []
    }
}
