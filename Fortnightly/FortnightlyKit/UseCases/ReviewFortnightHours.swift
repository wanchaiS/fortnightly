import Foundation

public enum ReviewFortnightHoursError: Error, Equatable {
    case recordsUnavailable
}

extension ReviewFortnightHoursError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .recordsUnavailable: "Your fortnight hours couldn't be worked out right now."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .recordsUnavailable: "Your shifts are safe. Close and reopen Fortnightly; if it keeps happening, restart your phone."
        }
    }
}

/// The two work fortnights that contain a given day.
public struct FortnightHoursReview: Equatable, Sendable {
    /// Began on last week's Monday and ends this Sunday.
    public let fortnightStartedLastWeek: FortnightWorkSummary
    /// Begins on this week's Monday.
    public let fortnightStartingThisWeek: FortnightWorkSummary
}

/// Works out how many hours count toward the visa work limit in both fortnights containing a day.
public struct ReviewFortnightHours: Sendable {
    private let shifts: any ShiftRepository
    private let courseBreaks: any CourseBreakRepository
    private let calendar: Calendar

    /// `calendar` supplies the time zone; work fortnights always start on Monday whatever its first weekday.
    public init(shifts: any ShiftRepository, courseBreaks: any CourseBreakRepository, calendar: Calendar = .current) {
        self.shifts = shifts
        self.courseBreaks = courseBreaks
        self.calendar = calendar
    }

    /// Both work fortnights containing `date`, with the hours that count toward the 48-hour limit.
    public func execute(on date: Date) throws(ReviewFortnightHoursError) -> FortnightHoursReview {
        let fortnights = WorkFortnight.containing(date, calendar: calendar)
        let bothFortnights = DateInterval(start: fortnights.startedLastWeek.startsOn, end: fortnights.startingThisWeek.interval.end)
        let countedShifts: [Shift]
        let breaks: [CourseBreak]
        do {
            countedShifts = try shifts.shiftsCountingTowardWorkLimit(overlapping: bothFortnights)
            breaks = try courseBreaks.courseBreaks(overlapping: bothFortnights)
        } catch {
            throw .recordsUnavailable
        }
        func summary(of fortnight: WorkFortnight) -> FortnightWorkSummary {
            FortnightWorkSummary(fortnight: fortnight, shifts: countedShifts, courseBreaks: breaks, calendar: calendar)
        }
        return FortnightHoursReview(
            fortnightStartedLastWeek: summary(of: fortnights.startedLastWeek),
            fortnightStartingThisWeek: summary(of: fortnights.startingThisWeek)
        )
    }
}
