import Foundation

/// When the student says they started work.
public enum ClockInTime: Equatable, Sendable {
    /// "Started on time": the rostered start, even if they confirm later.
    case asRostered
    /// "Started just now".
    case now
    case at(Date)
}

public enum ClockIntoShiftError: Error, Equatable {
    case shiftNotFound
    case alreadyClockedIn(since: Date)
    case alreadyFinished
    case markedNotWorked
    case anotherShiftInProgress(employerName: String, since: Date)
    case tooEarly(rosteredStart: Date)
    case afterRosteredFinish(rosteredFinish: Date)
    case timeInFuture
    case recordsUnavailable
}

/// Records that the student has started a rostered shift.
public struct ClockIntoShift: Sendable {
    /// Clocking in earlier than this before the rostered start usually means the wrong shift.
    public static let earliestClockInMinutesBeforeStart: Double = 60

    private let shifts: any ShiftRepository
    private let employers: any EmployerRepository
    private let reminders: any ShiftReminderScheduling
    private let display: any ShiftDisplayRefreshing
    private let now: @Sendable () -> Date

    public init(
        shifts: any ShiftRepository,
        employers: any EmployerRepository,
        reminders: any ShiftReminderScheduling,
        display: any ShiftDisplayRefreshing,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.shifts = shifts
        self.employers = employers
        self.reminders = reminders
        self.display = display
        self.now = now
    }

    @discardableResult
    public func execute(shiftID: Shift.ID, startedAt time: ClockInTime) throws(ClockIntoShiftError) -> Shift {
        // TDD red: not implemented yet.
        throw .shiftNotFound
    }
}
