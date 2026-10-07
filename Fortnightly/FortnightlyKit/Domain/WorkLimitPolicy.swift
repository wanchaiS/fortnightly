/// Student visa condition 8105: at most 48 hours of work in any work fortnight while the course is in session.
public enum WorkLimitPolicy {
    public static let hoursPerFortnight: Double = 48
    /// Product rule: warn early so the student can turn down an extra shift.
    public static let approachingFromHours: Double = 40

    static func status(forHours hours: Double) -> WorkLimitStatus {
        if hours > hoursPerFortnight { return .overLimit }
        if hours >= approachingFromHours { return .approachingLimit }
        return .withinLimit
    }
}
