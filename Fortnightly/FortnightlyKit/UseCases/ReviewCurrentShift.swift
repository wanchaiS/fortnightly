import Foundation

public enum ReviewCurrentShiftError: Error, Equatable {
    case recordsUnavailable
}

extension ReviewCurrentShiftError: LocalizedError {
    public var errorDescription: String? {
        "Your current shift couldn't be checked right now."
    }

    public var recoverySuggestion: String? {
        "Your shifts are safe. Close and reopen Fortnightly."
    }
}

/// The one thing the dock and the widget show.
public enum CurrentShift: Equatable, Sendable {
    /// Still clocked in after the rostered finish.
    case clockOutDue(ShiftListing)
    case onShift(ShiftListing)
    /// The rostered start has passed without a clock-in, and the rostered finish hasn't.
    case clockInDue(ShiftListing)
    /// Finished without a clock-in; its hours count until the student says whether they worked it.
    case missed(ShiftListing)
    case next(ShiftListing)
    case nothingRostered
}

public struct ReviewCurrentShift: Sendable {
    private let shifts: any ShiftRepository
    private let employers: any EmployerRepository
    private let now: @Sendable () -> Date

    public init(shifts: any ShiftRepository, employers: any EmployerRepository, now: @escaping @Sendable () -> Date = Date.init) {
        self.shifts = shifts
        self.employers = employers
        self.now = now
    }

    /// In the dock's order: clocking out or in comes first, then a missed shift, then the next shift.
    public func execute() throws(ReviewCurrentShiftError) -> CurrentShift {
        let currentTime = now()
        do {
            func listing(_ shift: Shift) throws -> ShiftListing {
                ShiftListing(shift: shift, employer: try employers.employer(withID: shift.employerID))
            }
            if let open = try shifts.openShift() {
                return open.rosteredFinish <= currentTime ? .clockOutDue(try listing(open)) : .onShift(try listing(open))
            }
            let rostered = try shifts.rosteredShifts()
            if let started = rostered.first(where: { $0.rosteredStart <= currentTime && currentTime < $0.rosteredFinish }) {
                return .clockInDue(try listing(started))
            }
            if let missed = rostered.first(where: { $0.rosteredFinish <= currentTime }) {
                return .missed(try listing(missed))
            }
            if let next = rostered.first(where: { $0.rosteredStart > currentTime }) {
                return .next(try listing(next))
            }
            return .nothingRostered
        } catch {
            throw .recordsUnavailable
        }
    }
}
