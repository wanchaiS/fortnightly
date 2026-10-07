import Foundation

/// What the student enters when adding a shift their manager has given them, or changing one already rostered.
public struct ShiftRosterRequest: Sendable {
    public var employerID: Employer.ID
    public var start: Date
    public var finish: Date
    public var note: String?
    /// The student has been warned this shift takes a fortnight over the work limit and wants it recorded anyway.
    public var acknowledgingWorkLimitBreach: Bool
    /// The rostered shift whose times are being changed; `nil` adds a new shift.
    public var editing: Shift.ID?

    public init(
        employerID: Employer.ID,
        start: Date,
        finish: Date,
        note: String? = nil,
        acknowledgingWorkLimitBreach: Bool = false,
        editing: Shift.ID? = nil
    ) {
        self.employerID = employerID
        self.start = start
        self.finish = finish
        self.note = note
        self.acknowledgingWorkLimitBreach = acknowledgingWorkLimitBreach
        self.editing = editing
    }
}

public enum RosterShiftError: Error, Equatable {
    case finishesBeforeStart
    case tooLong(hours: Double)
    case alreadyFinished
    case employerUnavailable
    case shiftNotFound
    case alreadyClockedIn(since: Date)
    case overlaps(employerName: String, existingShift: DateInterval)
    case wouldBreachWorkLimit(fortnight: WorkFortnight, projectedHours: Double)
    case recordsUnavailable
}

extension RosterShiftError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .finishesBeforeStart:
            "This shift finishes before it starts."
        case let .tooLong(hours):
            "This shift would be \(hours.hoursDescription) hours long."
        case .alreadyFinished:
            "This shift has already finished."
        case .employerUnavailable:
            "This employer is no longer in your list."
        case .shiftNotFound:
            "This shift is no longer on your roster."
        case let .alreadyClockedIn(since):
            "You've already clocked in to this shift (at \(since.formatted(date: .omitted, time: .shortened))), so its rostered times can't change."
        case let .overlaps(employerName, existingShift):
            "This overlaps your \(employerName) shift (\(existingShift.shiftTimesDescription))."
        case let .wouldBreachWorkLimit(fortnight, projectedHours):
            "This shift would take you to \(projectedHours.hoursDescription) of \(WorkLimitPolicy.hoursPerFortnight.hoursDescription) hours for \(fortnight.datesDescription)."
        case .recordsUnavailable:
            "Your shift couldn't be saved right now."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .finishesBeforeStart:
            "For a shift that ends after midnight, set the finish to the next day."
        case .tooLong:
            "Check AM and PM on the start and finish. Shifts longer than \(RosterShift.longestRosteredShiftHours.hoursDescription) hours can't be rostered."
        case .alreadyFinished:
            "To add hours you've already worked, tap the day on the Fortnight screen and choose Log a past shift."
        case .employerUnavailable:
            "Choose another employer, or add them again in Jobs."
        case .shiftNotFound:
            "Check your shifts on the Fortnight screen."
        case .alreadyClockedIn:
            "Correct the actual times from the shift's details after you clock out."
        case .overlaps:
            "You can't be at two shifts at once. Change these times or edit the other shift."
        case .wouldBreachWorkLimit:
            "Your student visa allows \(WorkLimitPolicy.hoursPerFortnight.hoursDescription) hours a fortnight during semester. Ask your manager to shorten or swap this shift. You can still save it so your record stays accurate."
        case .recordsUnavailable:
            "Your other shifts are safe. Try again; if it keeps happening, restart Fortnightly."
        }
    }
}

/// Adds an upcoming shift to the student's roster and schedules its clock-in and clock-out prompts.
public struct RosterShift: Sendable {
    /// Rostered times longer than this are almost always an AM/PM mistake.
    public static let longestRosteredShiftHours: Double = 14

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

    /// Saves the shift as rostered, then schedules its prompts and refreshes the widget.
    @discardableResult
    public func execute(_ request: ShiftRosterRequest) throws(RosterShiftError) -> Shift {
        let assessment = try assess(request, at: now())
        if !request.acknowledgingWorkLimitBreach,
           let breach = assessment.effects.first(where: { $0.after.status == .overLimit }) {
            throw .wouldBreachWorkLimit(fortnight: breach.fortnight, projectedHours: breach.after.hoursTowardLimit)
        }
        try read { try shifts.save(assessment.shift) }
        if request.editing != nil {
            reminders.cancelAllReminders(for: assessment.shift.id)
        }
        reminders.scheduleReminders(for: assessment.shift, employerName: assessment.employer.name)
        display.shiftsDidChange()
        return assessment.shift
    }

    /// The shift's effect on every work fortnight it falls in, earliest first, without saving anything.
    /// Checks the same rules as `execute`; a breach shows in the effects instead of being thrown.
    public func preview(_ request: ShiftRosterRequest) throws(RosterShiftError) -> [FortnightEffect] {
        try assess(request, at: now()).effects
    }

    private struct Assessment {
        let employer: Employer
        let shift: Shift
        let effects: [FortnightEffect]
    }

    /// Every rule except the work limit, plus the shift's effect on each fortnight it falls in.
    private func assess(_ request: ShiftRosterRequest, at currentTime: Date) throws(RosterShiftError) -> Assessment {
        guard request.finish > request.start else { throw .finishesBeforeStart }
        let rosteredTime = DateInterval(start: request.start, end: request.finish)
        let hours = rosteredTime.duration / 3600
        guard hours <= Self.longestRosteredShiftHours else { throw .tooLong(hours: hours) }
        guard request.finish > currentTime else { throw .alreadyFinished }
        guard let employer = try read({ try employers.employer(withID: request.employerID) }), !employer.isArchived else {
            throw .employerUnavailable
        }
        // Changing times: only before clocking in, and the shift's old times never clash with its new ones.
        // A shift marked not working can be put back on the roster this way.
        if let editedID = request.editing {
            guard let edited = try read({ try shifts.shift(withID: editedID) }) else { throw .shiftNotFound }
            if let clockedInAt = edited.clockedInAt { throw .alreadyClockedIn(since: clockedInAt) }
        }

        let fortnights = WorkFortnight.overlapping(rosteredTime, calendar: calendar)
        let affectedTime = DateInterval(start: fortnights.first!.startsOn, end: fortnights.last!.interval.end)
        let existingShifts = try read { try shifts.shiftsCountingTowardWorkLimit(overlapping: affectedTime) }
        let otherShifts = existingShifts.filter { $0.id != request.editing }
        let breaks = try read { try courseBreaks.courseBreaks(overlapping: affectedTime) }

        if let clash = otherShifts.firstClash(with: rosteredTime, asOf: currentTime) {
            let clashEmployerName = try read { try employers.employer(withID: clash.shift.employerID)?.name }
            throw .overlaps(employerName: clashEmployerName ?? "other", existingShift: clash.time)
        }

        let shift = Shift(
            id: request.editing ?? UUID(),
            employerID: employer.id,
            rosteredStart: request.start,
            rosteredFinish: request.finish,
            note: request.note
        )
        func summary(_ fortnight: WorkFortnight, _ counted: [Shift]) -> FortnightWorkSummary {
            FortnightWorkSummary(fortnight: fortnight, shifts: counted, courseBreaks: breaks, calendar: calendar, now: currentTime)
        }
        let effects = fortnights.map { FortnightEffect(before: summary($0, existingShifts), after: summary($0, otherShifts + [shift])) }
        return Assessment(employer: employer, shift: shift, effects: effects)
    }

    private func read<Value>(_ operation: () throws -> Value) throws(RosterShiftError) -> Value {
        do {
            return try operation()
        } catch {
            throw .recordsUnavailable
        }
    }
}
