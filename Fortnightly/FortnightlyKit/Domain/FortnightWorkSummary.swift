import Foundation

public enum WorkLimitStatus: Equatable, Sendable {
    case withinLimit
    case approachingLimit
    case overLimit
}

/// How many hours of one work fortnight count toward the student visa work limit.
public struct FortnightWorkSummary: Equatable, Sendable {
    public let fortnight: WorkFortnight
    /// Worked and rostered hours inside this fortnight, excluding course-break days.
    public let hoursTowardLimit: Double
    /// Hours already worked: finished shifts, plus an open shift up to now.
    public let hoursWorked: Double
    /// Hours still to come: rostered shifts, plus the rest of an open shift.
    public let hoursRostered: Double
    public let status: WorkLimitStatus

    init(fortnight: WorkFortnight, shifts: [Shift], courseBreaks: [CourseBreak], calendar: Calendar, now: Date) {
        let breakDays = courseBreaks.map { $0.interval(in: calendar) }
        let seconds = shifts.reduce(into: TimeInterval(0)) { total, shift in
            // Only the part of a shift inside this fortnight counts, so a shift crossing
            // Sunday midnight is split between the weeks it was worked in.
            guard let worked = shift.timeTowardWorkLimit,
                  let insideFortnight = worked.intersection(with: fortnight.interval)
            else { return }
            total += insideFortnight.duration(excluding: breakDays)
        }
        self.fortnight = fortnight
        hoursTowardLimit = seconds / 3600
        // TDD red: the worked/rostered split isn't implemented yet.
        hoursWorked = 0
        hoursRostered = hoursTowardLimit
        status = WorkLimitPolicy.status(forHours: hoursTowardLimit)
    }
}

private extension DateInterval {
    /// Seconds of this interval not covered by any of `exclusions` (which may overlap each other).
    func duration(excluding exclusions: [DateInterval]) -> TimeInterval {
        var covered: TimeInterval = 0
        var coveredUntil = start
        for exclusion in exclusions.sorted(by: { $0.start < $1.start }) {
            let overlapStart = Swift.max(exclusion.start, coveredUntil)
            let overlapEnd = Swift.min(exclusion.end, end)
            if overlapEnd > overlapStart {
                covered += overlapEnd.timeIntervalSince(overlapStart)
                coveredUntil = overlapEnd
            }
        }
        return duration - covered
    }
}
