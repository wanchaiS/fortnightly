import Foundation

/// Dates when the student's course is not in session. The work limit doesn't apply on these days.
public struct CourseBreak: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    /// Any time on the first day of the break.
    public var startsOn: Date
    /// Any time on the last day of the break (inclusive).
    public var endsOn: Date

    public init(id: UUID = UUID(), name: String, startsOn: Date, endsOn: Date) {
        self.id = id
        self.name = name
        self.startsOn = startsOn
        self.endsOn = endsOn
    }
}

extension CourseBreak {
    /// From midnight on the first day to midnight after the last day, in `calendar`'s time zone.
    func interval(in calendar: Calendar) -> DateInterval {
        let firstDay = calendar.startOfDay(for: startsOn)
        let dayAfterLast = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endsOn))!
        return DateInterval(start: firstDay, end: Swift.max(firstDay, dayAfterLast))
    }
}
