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

    public func execute(on date: Date) throws(ReviewFortnightHoursError) -> FortnightHoursReview {
        // TDD red: not implemented yet.
        let nothingCounted = FortnightWorkSummary(
            fortnight: WorkFortnight(interval: DateInterval(start: date, duration: 0)),
            hoursTowardLimit: 0,
            status: .withinLimit
        )
        return FortnightHoursReview(fortnightStartedLastWeek: nothingCounted, fortnightStartingThisWeek: nothingCounted)
    }
}
