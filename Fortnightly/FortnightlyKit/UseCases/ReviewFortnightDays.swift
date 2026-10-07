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

    /// A shift is listed on the day it was rostered to start, even when it runs past midnight.
    public func execute(for fortnight: WorkFortnight) throws(ReviewFortnightDaysError) -> [WorkDay] {
        let currentTime = now()
        let rostered: [Shift]
        let employersByID: [Employer.ID: Employer]
        let breakDays: [DateInterval]
        do {
            rostered = try shifts.shifts(rosteredToStartIn: fortnight.interval)
            employersByID = Dictionary(uniqueKeysWithValues: try employers.employers(includingArchived: true).map { ($0.id, $0) })
            breakDays = try courseBreaks.courseBreaks(overlapping: fortnight.interval).map { $0.interval(in: calendar) }
        } catch {
            throw .recordsUnavailable
        }

        return (0 ..< 14).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: fortnight.startsOn)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            let shiftsThatDay = rostered
                .filter { $0.rosteredStart >= day && $0.rosteredStart < nextDay }
                .sorted { $0.rosteredStart < $1.rosteredStart }
            let seconds = shiftsThatDay.compactMap { $0.timeTowardWorkLimit(asOf: currentTime)?.duration }.reduce(0, +)
            return WorkDay(
                date: day,
                shifts: shiftsThatDay.map { ShiftListing(shift: $0, employer: employersByID[$0.employerID]) },
                hours: seconds / 3600,
                isInCourseBreak: breakDays.contains { $0.start <= day && day < $0.end }
            )
        }
    }
}
