import Foundation

/// When the student says they finished work.
public enum ClockOutTime: Equatable, Sendable {
    /// "Finished on time": the rostered finish.
    case asRostered
    /// "Finished just now".
    case now
    case at(Date)
}

/// The recorded shift and what it did to the work fortnights it falls in.
public struct ClockOutOutcome: Equatable, Sendable {
    public let workedShift: Shift
    /// Every work fortnight the shift falls in, earliest first, including the hours it added.
    public let fortnights: [FortnightWorkSummary]

    public var fortnightsOverLimit: [FortnightWorkSummary] {
        fortnights.filter { $0.status == .overLimit }
    }
}

public enum ClockOutOfShiftError: Error, Equatable {
    case shiftNotFound
    case notClockedIn
    case finishBeforeClockIn(clockedInAt: Date)
    case rosteredFinishNotReached(rosteredFinish: Date)
    case timeInFuture
    case unusuallyLong(hours: Double)
    case recordsUnavailable
}

/// Records that the student has finished a shift they clocked into.
public struct ClockOutOfShift: Sendable {
    /// A worked shift longer than this almost always means a forgotten clock-out.
    public static let longestWorkedShiftHours: Double = 16

    private let shifts: any ShiftRepository
    private let courseBreaks: any CourseBreakRepository
    private let reminders: any ShiftReminderScheduling
    private let display: any ShiftDisplayRefreshing
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public init(
        shifts: any ShiftRepository,
        courseBreaks: any CourseBreakRepository,
        reminders: any ShiftReminderScheduling,
        display: any ShiftDisplayRefreshing,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.shifts = shifts
        self.courseBreaks = courseBreaks
        self.reminders = reminders
        self.display = display
        self.calendar = calendar
        self.now = now
    }

    @discardableResult
    public func execute(shiftID: Shift.ID, finishedAt time: ClockOutTime) throws(ClockOutOfShiftError) -> ClockOutOutcome {
        // TDD red: not implemented yet.
        throw .shiftNotFound
    }
}
