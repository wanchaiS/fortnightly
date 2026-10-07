import Foundation

/// The real times of a finished shift: a new past shift, a missed one, or a correction to a worked one.
public struct PastShiftRequest: Sendable {
    public enum Subject: Equatable, Sendable {
        /// A shift that was never on the roster ("Log a past shift").
        case newShift(employerID: Employer.ID)
        /// A rostered shift that finished without a clock-in ("Yes, enter my times").
        case missedShift(Shift.ID)
        /// A worked shift whose clocked times were wrong ("Correct times").
        case workedShift(Shift.ID)
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
    case shiftNotFound
    case notMissed
    case nothingToCorrect
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
        case .shiftNotFound:
            "This shift is no longer on your roster."
        case .notMissed:
            "This shift already has its hours recorded."
        case .nothingToCorrect:
            "This shift has no worked times to correct yet."
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
        case .shiftNotFound:
            "Check your shifts on the Fortnight screen."
        case .notMissed:
            "To change its times, open the shift and choose Correct times."
        case .nothingToCorrect:
            "If you worked it, open the shift and enter your times."
        case .overlaps:
            "You can't have worked two shifts at once. Check the times of both shifts."
        case .recordsUnavailable:
            "Your other shifts are safe. Try again."
        }
    }
}

/// Records the real times of a finished shift, so the record matches what happened.
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

    /// Saves the shift as worked with the given times, stops any prompts it still had, and reports
    /// what it did to the fortnights. A breach is still recorded: the record must match what happened.
    @discardableResult
    public func execute(_ request: PastShiftRequest) throws(LogPastShiftError) -> WorkedShiftOutcome {
        let currentTime = now()
        guard request.finish > request.start else { throw .finishesBeforeStart }
        guard request.finish <= currentTime else { throw .notFinishedYet }
        let workedTime = DateInterval(start: request.start, end: request.finish)
        let hours = workedTime.duration / 3600
        guard hours <= Self.longestWorkedShiftHours else { throw .unusuallyLong(hours: hours) }

        var shift: Shift
        switch request.subject {
        case let .newShift(employerID):
            // Past hours can belong to a job the student has since left, so archived employers are fine.
            guard try read({ try employers.employer(withID: employerID) }) != nil else { throw .employerUnavailable }
            shift = Shift(employerID: employerID, rosteredStart: request.start, rosteredFinish: request.finish)
        case let .missedShift(id):
            guard let missed = try read({ try shifts.shift(withID: id) }) else { throw .shiftNotFound }
            guard missed.status == .rostered, missed.rosteredFinish <= currentTime else { throw .notMissed }
            shift = missed
        case .workedShift:
            // TDD red: not implemented yet.
            throw .recordsUnavailable
        }
        shift.clockedInAt = request.start
        shift.clockedOutAt = request.finish
        shift.status = .worked

        let fortnights = WorkFortnight.overlapping(workedTime, calendar: calendar)
        let affectedTime = DateInterval(start: fortnights.first!.startsOn, end: fortnights.last!.interval.end)
        let otherShifts = try read { try shifts.shiftsCountingTowardWorkLimit(overlapping: affectedTime) }.filter { $0.id != shift.id }
        let breaks = try read { try courseBreaks.courseBreaks(overlapping: affectedTime) }
        if let clash = otherShifts.firstClash(with: workedTime, asOf: currentTime) {
            let clashEmployerName = try read { try employers.employer(withID: clash.shift.employerID)?.name }
            throw .overlaps(employerName: clashEmployerName ?? "other", existingShift: clash.time)
        }

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

    private func read<Value>(_ operation: () throws -> Value) throws(LogPastShiftError) -> Value {
        do {
            return try operation()
        } catch {
            throw .recordsUnavailable
        }
    }
}
