import Foundation

/// 14 days from midnight on a Monday: the period the student visa work limit is measured over.
/// Every Monday starts one, so every week belongs to two work fortnights.
public struct WorkFortnight: Equatable, Sendable {
    public let interval: DateInterval

    public var startsOn: Date { interval.start }

    init(interval: DateInterval) {
        self.interval = interval
    }

    /// The work fortnight beginning on the Monday of `date`'s week, at midnight in `calendar`'s time zone.
    public static func starting(inWeekOf date: Date, calendar: Calendar) -> WorkFortnight {
        let calendar = calendar.mondayFirst
        let monday = calendar.dateInterval(of: .weekOfYear, for: date)!.start
        // Adding days (not seconds) keeps midnight-to-midnight across daylight-saving changes.
        let end = calendar.date(byAdding: .day, value: 14, to: monday)!
        return WorkFortnight(interval: DateInterval(start: monday, end: end))
    }

    /// Both work fortnights that contain `date`.
    public static func containing(_ date: Date, calendar: Calendar) -> (startedLastWeek: WorkFortnight, startingThisWeek: WorkFortnight) {
        let startingThisWeek = starting(inWeekOf: date, calendar: calendar)
        let dayInLastWeek = calendar.date(byAdding: .day, value: -7, to: startingThisWeek.startsOn)!
        return (starting(inWeekOf: dayInLastWeek, calendar: calendar), startingThisWeek)
    }

    /// Every work fortnight that shares time with `interval`, earliest first.
    static func overlapping(_ interval: DateInterval, calendar: Calendar) -> [WorkFortnight] {
        var fortnights: [WorkFortnight] = []
        var fortnight = containing(interval.start, calendar: calendar).startedLastWeek
        while fortnight.startsOn < interval.end {
            fortnights.append(fortnight)
            let nextMonday = calendar.date(byAdding: .day, value: 7, to: fortnight.startsOn)!
            fortnight = starting(inWeekOf: nextMonday, calendar: calendar)
        }
        return fortnights
    }
}

extension Calendar {
    /// Work fortnights start on Monday whatever the phone's region says the first weekday is.
    var mondayFirst: Calendar {
        var calendar = self
        calendar.firstWeekday = 2
        return calendar
    }
}
