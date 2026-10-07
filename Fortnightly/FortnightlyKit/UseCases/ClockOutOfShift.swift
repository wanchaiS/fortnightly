import Foundation

/// When the student says they finished work.
public enum ClockOutTime: Equatable, Sendable {
    /// "Finished on time": the rostered finish.
    case asRostered
    /// "Finished just now".
    case now
    case at(Date)
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

extension ClockOutOfShiftError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .shiftNotFound:
            "This shift no longer exists."
        case .notClockedIn:
            "You're not clocked in to this shift."
        case let .finishBeforeClockIn(clockedInAt):
            "That finish time is before you clocked in (\(clockedInAt.formatted(date: .omitted, time: .shortened)))."
        case let .rosteredFinishNotReached(rosteredFinish):
            "Your rostered finish (\(rosteredFinish.formatted(date: .omitted, time: .shortened))) hasn't happened yet."
        case .timeInFuture:
            "You can't clock out at a time that hasn't happened yet."
        case let .unusuallyLong(hours):
            "That would record a \(hours.hoursDescription)-hour shift."
        case .recordsUnavailable:
            "Your clock-out couldn't be saved."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .shiftNotFound:
            "Check your shifts in Hours."
        case .notClockedIn:
            "If you worked it, add it with Log a past shift."
        case let .finishBeforeClockIn(clockedInAt):
            "Pick a time after \(clockedInAt.formatted(date: .omitted, time: .shortened))."
        case .rosteredFinishNotReached:
            "If you finished early, choose \"Finished just now\"."
        case .timeInFuture:
            "Choose \"Finished just now\", or wait until you finish."
        case .unusuallyLong:
            "If you forgot to clock out, enter the time you actually finished."
        case .recordsUnavailable:
            "Try again. If it keeps failing, note your finish time and correct the shift later from its details."
        }
    }
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

    /// Records the shift as worked, stops its prompts, refreshes the widget, and reports what it did to the fortnights.
    /// A shift that takes a fortnight over the limit is still recorded: the record must match what happened.
    @discardableResult
    public func execute(shiftID: Shift.ID, finishedAt time: ClockOutTime) throws(ClockOutOfShiftError) -> WorkedShiftOutcome {
        let currentTime = now()
        guard var shift = try read({ try shifts.shift(withID: shiftID) }) else { throw .shiftNotFound }
        guard shift.status == .onShift, let clockedInAt = shift.clockedInAt else { throw .notClockedIn }

        if time == .asRostered, shift.rosteredFinish > currentTime {
            throw .rosteredFinishNotReached(rosteredFinish: shift.rosteredFinish)
        }
        let finishedAt = switch time {
        case .asRostered: shift.rosteredFinish
        case .now: currentTime
        case let .at(date): date
        }
        guard finishedAt <= currentTime else { throw .timeInFuture }
        guard finishedAt > clockedInAt else { throw .finishBeforeClockIn(clockedInAt: clockedInAt) }
        let hours = finishedAt.timeIntervalSince(clockedInAt) / 3600
        guard hours <= Self.longestWorkedShiftHours else { throw .unusuallyLong(hours: hours) }

        let fortnights = WorkFortnight.overlapping(DateInterval(start: clockedInAt, end: finishedAt), calendar: calendar)
        let affectedTime = DateInterval(start: fortnights.first!.startsOn, end: fortnights.last!.interval.end)
        // Read before saving, so a failed read never reports an already-saved clock-out as unsaved.
        let otherShifts = try read { try shifts.shiftsCountingTowardWorkLimit(overlapping: affectedTime) }.filter { $0.id != shift.id }
        let breaks = try read { try courseBreaks.courseBreaks(overlapping: affectedTime) }

        shift.clockedOutAt = finishedAt
        shift.status = .worked
        try read { try shifts.save(shift) }
        reminders.cancelAllReminders(for: shift.id)
        display.shiftsDidChange()

        return WorkedShiftOutcome(
            workedShift: shift,
            fortnights: fortnights.map {
                FortnightWorkSummary(fortnight: $0, shifts: otherShifts + [shift], courseBreaks: breaks, calendar: calendar, now: currentTime)
            }
        )
    }

    private func read<Value>(_ operation: () throws -> Value) throws(ClockOutOfShiftError) -> Value {
        do {
            return try operation()
        } catch {
            throw .recordsUnavailable
        }
    }
}
