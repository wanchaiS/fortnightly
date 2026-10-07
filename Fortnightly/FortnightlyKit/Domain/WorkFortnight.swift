import Foundation

/// 14 days from midnight on a Monday: the period the student visa work limit is measured over.
/// Every Monday starts one, so every week belongs to two work fortnights.
public struct WorkFortnight: Equatable, Sendable {
    public let interval: DateInterval

    public var startsOn: Date { interval.start }

    init(interval: DateInterval) {
        self.interval = interval
    }
}
