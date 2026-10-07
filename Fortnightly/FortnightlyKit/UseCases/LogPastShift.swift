import Foundation

/// Hours worked that weren't clocked: a new past shift, or the real times of a missed one.
public struct PastShiftRequest: Sendable {
    public enum Subject: Equatable, Sendable {
        /// A shift that was never on the roster ("Log a past shift").
        case newShift(employerID: Employer.ID)
        /// A rostered shift that finished without a clock-in ("Yes, enter my times").
        case missedShift(Shift.ID)
    }

    public var subject: Subject
    public var start: Date
    public var finish: Date

    public init(subject: Subject, start: Date, finish: Date) {
        self.subject = subject
        self.start = start
        self.finish = finish
    }
}

public enum LogPastShiftError: Error, Equatable {
    case finishesBeforeStart
    case notFinishedYet
    case unusuallyLong(hours: Double)
    case employerUnavailable
    case missedShiftNotFound
    case notMissed
    case overlaps(employerName: String, existingShift: DateInterval)
    case recordsUnavailable
}

extension LogPastShiftError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .finishesBeforeStart:
            "This shift finishes before it starts."
        case .notFinishedYet:
            "This shift hasn't finished yet."
        case let .unusuallyLong(hours):
            "That would record a \(hours.hoursDescription)-hour shift."
        case .employerUnavailable:
            "This employer is no longer in your list."
        case .missedShiftNotFound:
            "This shift is no longer on your roster."
        case .notMissed:
            "This shift already has its hours recorded."
        case let .overlaps(employerName, existingShift):
            "This overlaps your \(employerName) shift (\(existingShift.shiftTimesDescription))."
        case .recordsUnavailable:
            "This shift couldn't be saved."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .finishesBeforeStart:
            "For a shift that ended after midnight, set the finish to the next day."
        case .notFinishedYet:
            "Clock in and out of shifts that are still happening; log only shifts you've finished."
        case .unusuallyLong:
            "Check the start and finish times. Shifts longer than \(LogPastShift.longestWorkedShiftHours.hoursDescription) hours can't be logged."
        case .employerUnavailable:
            "Choose another employer, or add them again in Jobs."
        case .missedShiftNotFound:
            "Check your shifts on the Fortnight screen."
        case .notMissed:
            "To change its times, open the shift and choose Correct times."
        case .overlaps:
            "You can't have worked two shifts at once. Check the times of both shifts."
        case .recordsUnavailable:
            "Your other shifts are safe. Try again."
        }
    }
}

/// Records hours that were worked without clocking in and out, so the record matches what happened.
public struct LogPastShift: Sendable {
    /// Longer than this almost always means a typo in the times.
    public static let longestWorkedShiftHours: Double = ClockOutOfShift.longestWorkedShiftHours

    private let shifts: any ShiftRepository
    private let employers: any EmployerRepository
    private let courseBreaks: any CourseBreakRepository
    private let reminders: any ShiftReminderScheduling
    private let display: any ShiftDisplayRefreshing
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public init(
        shifts: any ShiftRepository,
        employers: any EmployerRepository,
        courseBreaks: any CourseBreakRepository,
        reminders: any ShiftReminderScheduling,
        display: any ShiftDisplayRefreshing,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.shifts = shifts
        self.employers = employers
        self.courseBreaks = courseBreaks
        self.reminders = reminders
        self.display = display
        self.calendar = calendar
        self.now = now
    }

    @discardableResult
    public func execute(_ request: PastShiftRequest) throws(LogPastShiftError) -> WorkedShiftOutcome {
        // TDD red: not implemented yet.
        throw .recordsUnavailable
    }
}
