import Foundation

public enum MarkShiftNotWorkedError: Error, Equatable {
    case shiftNotFound
    case alreadyClockedIn(since: Date)
    case alreadyWorked
    case recordsUnavailable
}

extension MarkShiftNotWorkedError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .shiftNotFound:
            "This shift is no longer on your roster."
        case let .alreadyClockedIn(since):
            "You clocked in to this shift at \(since.formatted(date: .omitted, time: .shortened))."
        case .alreadyWorked:
            "You've already recorded hours for this shift."
        case .recordsUnavailable:
            "This change couldn't be saved."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .shiftNotFound:
            "Check your shifts on the Fortnight screen."
        case .alreadyClockedIn:
            "Clock out instead, with the time you finished."
        case .alreadyWorked:
            "If the times are wrong, correct them from the shift's details."
        case .recordsUnavailable:
            "Your shifts are safe. Try again."
        }
    }
}

/// Records that a rostered shift didn't happen (cancelled, swapped, or missed), so its hours stop counting.
public struct MarkShiftNotWorked: Sendable {
    private let shifts: any ShiftRepository
    private let reminders: any ShiftReminderScheduling
    private let display: any ShiftDisplayRefreshing

    public init(shifts: any ShiftRepository, reminders: any ShiftReminderScheduling, display: any ShiftDisplayRefreshing) {
        self.shifts = shifts
        self.reminders = reminders
        self.display = display
    }

    public func execute(shiftID: Shift.ID) throws(MarkShiftNotWorkedError) {
        // TDD red: not implemented yet.
    }
}
