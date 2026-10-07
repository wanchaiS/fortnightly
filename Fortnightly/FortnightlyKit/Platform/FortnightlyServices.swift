import Foundation

/// The use cases wired to their repositories and platform adapters. The app and both extensions
/// build one on the shared App Group store, so all three run the same rules.
public struct FortnightlyServices: Sendable {
    let shifts: any ShiftRepository
    let employers: any EmployerRepository
    let courseBreaks: any CourseBreakRepository
    let reminders: any ShiftReminderScheduling
    let display: any ShiftDisplayRefreshing
    let now: @Sendable () -> Date

    public init(
        shifts: any ShiftRepository,
        employers: any EmployerRepository,
        courseBreaks: any CourseBreakRepository,
        reminders: any ShiftReminderScheduling,
        display: any ShiftDisplayRefreshing,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.shifts = shifts
        self.employers = employers
        self.courseBreaks = courseBreaks
        self.reminders = reminders
        self.display = display
        self.now = now
    }

    public static func appGroup() throws -> FortnightlyServices {
        let store = try ShiftStore.appGroup.get()
        return FortnightlyServices(
            shifts: CoreDataShiftRepository(store: store),
            employers: CoreDataEmployerRepository(store: store),
            courseBreaks: CoreDataCourseBreakRepository(store: store),
            reminders: NotificationReminderScheduler(),
            display: WidgetDisplayRefresher()
        )
    }

    /// The same services with the clock set to `date`: the widget draws its future entries this way.
    public func asOf(_ date: Date) -> FortnightlyServices {
        FortnightlyServices(shifts: shifts, employers: employers, courseBreaks: courseBreaks, reminders: reminders, display: display, now: { date })
    }

    public var currentTime: Date { now() }

    // MARK: Reviewing

    public var reviewFortnightHours: ReviewFortnightHours {
        ReviewFortnightHours(shifts: shifts, courseBreaks: courseBreaks, now: now)
    }

    public var reviewFortnightDays: ReviewFortnightDays {
        ReviewFortnightDays(shifts: shifts, employers: employers, courseBreaks: courseBreaks, now: now)
    }

    public var reviewCurrentShift: ReviewCurrentShift {
        ReviewCurrentShift(shifts: shifts, employers: employers, now: now)
    }

    public var reviewMissedShifts: ReviewMissedShifts {
        ReviewMissedShifts(shifts: shifts, employers: employers, now: now)
    }

    public var reviewJobs: ReviewJobs {
        ReviewJobs(employers: employers, courseBreaks: courseBreaks)
    }

    // MARK: Shifts

    public var rosterShift: RosterShift {
        RosterShift(shifts: shifts, employers: employers, courseBreaks: courseBreaks, reminders: reminders, display: display, now: now)
    }

    public var clockIntoShift: ClockIntoShift {
        ClockIntoShift(shifts: shifts, employers: employers, reminders: reminders, display: display, now: now)
    }

    public var clockOutOfShift: ClockOutOfShift {
        ClockOutOfShift(shifts: shifts, courseBreaks: courseBreaks, reminders: reminders, display: display, now: now)
    }

    public var markShiftNotWorked: MarkShiftNotWorked {
        MarkShiftNotWorked(shifts: shifts, reminders: reminders, display: display)
    }

    public var logPastShift: LogPastShift {
        LogPastShift(shifts: shifts, employers: employers, courseBreaks: courseBreaks, reminders: reminders, display: display, now: now)
    }

    public var refreshShiftReminders: RefreshShiftReminders {
        RefreshShiftReminders(shifts: shifts, employers: employers, reminders: reminders, now: now)
    }

    // MARK: Jobs

    public var addEmployer: AddEmployer {
        AddEmployer(employers: employers, display: display)
    }

    public var archiveEmployer: ArchiveEmployer {
        ArchiveEmployer(employers: employers, shifts: shifts, display: display, now: now)
    }

    public var recordCourseBreak: RecordCourseBreak {
        RecordCourseBreak(courseBreaks: courseBreaks, display: display)
    }

    public var removeCourseBreak: RemoveCourseBreak {
        RemoveCourseBreak(courseBreaks: courseBreaks, display: display)
    }
}
