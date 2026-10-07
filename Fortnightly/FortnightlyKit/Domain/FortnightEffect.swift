/// What one shift does to a work fortnight: its hours before and after the shift is counted.
public struct FortnightEffect: Equatable, Sendable {
    public let before: FortnightWorkSummary
    public let after: FortnightWorkSummary

    public var fortnight: WorkFortnight { after.fortnight }
}
