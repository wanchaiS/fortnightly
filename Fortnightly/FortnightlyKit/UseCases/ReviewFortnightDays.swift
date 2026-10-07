import Foundation

public enum ReviewFortnightDaysError: Error, Equatable {
    case recordsUnavailable
}

extension ReviewFortnightDaysError: LocalizedError {
    public var errorDescription: String? {
        "Your shifts for this fortnight couldn't be loaded right now."
    }

    public var recoverySuggestion: String? {
        "Your shifts are safe. Close and reopen Fortnightly."
    }
}

/// One of the 14 days of a work fortnight, as a row on the board.
public struct WorkDay: Identifiable, Equatable, Sendable {
    /// Midnight at the start of the day.
    public let date: Date
    /// Earliest first, including shifts not worked: the record shows them struck through.
    public let shifts: [ShiftListing]
    /// Worked and rostered hours of the shifts listed; a shift not worked adds none.
    public let hours: Double
    /// Hours on this day don't count toward the limit.
    public let isInCourseBreak: Bool

    public var id: Date { date }
}

public struct ReviewFortnightDays: Sendable {
    private let shifts: any ShiftRepository
    private let employers: any EmployerRepository
    private let courseBreaks: any CourseBreakRepository
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public init(
        shifts: any ShiftRepository,
        employers: any EmployerRepository,
        courseBreaks: any CourseBreakRepository,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.shifts = shifts
        self.employers = employers
        self.courseBreaks = courseBreaks
        self.calendar = calendar
        self.now = now
    }

    public func execute(for fortnight: WorkFortnight) throws(ReviewFortnightDaysError) -> [WorkDay] {
        // TDD red: not implemented yet.
        []
    }
}
