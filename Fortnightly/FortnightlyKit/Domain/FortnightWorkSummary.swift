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
        var worked: TimeInterval = 0
        var rostered: TimeInterval = 0
        for shift in shifts {
            // Only the part of a shift inside this fortnight counts, so a shift crossing
            // Sunday midnight is split between the weeks it was worked in.
            guard let time = shift.timeTowardWorkLimit(asOf: now),
                  let insideFortnight = time.intersection(with: fortnight.interval)
            else { continue }
            let counted = insideFortnight.duration(excluding: breakDays)
            switch shift.status {
            case .worked:
                worked += counted
            case .rostered:
                rostered += counted
            case .onShift:
                // Worked up to now; the rest of the shift is still to come.
                let workedSoFar = now > insideFortnight.start
                    ? DateInterval(start: insideFortnight.start, end: Swift.min(now, insideFortnight.end)).duration(excluding: breakDays)
                    : 0
                worked += workedSoFar
                rostered += counted - workedSoFar
            case .notWorked:
                break
            }
        }
        self.fortnight = fortnight
        hoursWorked = worked / 3600
        hoursRostered = rostered / 3600
        hoursTowardLimit = hoursWorked + hoursRostered
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
