import Foundation

/// What the student enters when adding a shift their manager has given them.
public struct ShiftRosterRequest: Sendable {
    public var employerID: Employer.ID
    public var start: Date
    public var finish: Date
    public var note: String?
    /// The student has been warned this shift takes a fortnight over the work limit and wants it recorded anyway.
    public var acknowledgingWorkLimitBreach: Bool

    public init(employerID: Employer.ID, start: Date, finish: Date, note: String? = nil, acknowledgingWorkLimitBreach: Bool = false) {
        self.employerID = employerID
        self.start = start
        self.finish = finish
        self.note = note
        self.acknowledgingWorkLimitBreach = acknowledgingWorkLimitBreach
    }
}

public enum RosterShiftError: Error, Equatable {
    case finishesBeforeStart
    case tooLong(hours: Double)
    case alreadyFinished
    case employerUnavailable
    case overlaps(employerName: String, existingShift: DateInterval)
    case wouldBreachWorkLimit(fortnight: WorkFortnight, projectedHours: Double)
    case recordsUnavailable
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

    @discardableResult
    public func execute(_ request: ShiftRosterRequest) throws(RosterShiftError) -> Shift {
        // TDD red: not implemented yet.
        Shift(employerID: request.employerID, rosteredStart: request.start, rosteredFinish: request.finish, note: request.note)
    }
}
