/// A shift just recorded as worked, and what it did to the work fortnights it falls in.
/// A worked breach is always recorded; this tells the student about it afterwards.
public struct WorkedShiftOutcome: Equatable, Sendable {
    public let workedShift: Shift
    /// Every work fortnight the shift falls in, earliest first, including the hours it added.
    public let fortnights: [FortnightWorkSummary]

    public var fortnightsOverLimit: [FortnightWorkSummary] {
        fortnights.filter { $0.status == .overLimit }
    }
}
