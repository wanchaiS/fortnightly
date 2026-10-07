/// A shift together with the name of the employer it's for, as lists show it.
public struct ShiftListing: Identifiable, Equatable, Sendable {
    public let shift: Shift
    public let employerName: String

    public var id: Shift.ID { shift.id }
}
