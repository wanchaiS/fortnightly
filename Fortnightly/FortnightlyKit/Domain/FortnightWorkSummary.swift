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
    public let status: WorkLimitStatus
}
