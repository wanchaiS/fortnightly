/// A shift as lists show it: with its employer's name and colour.
public struct ShiftListing: Identifiable, Equatable, Sendable {
    public let shift: Shift
    public let employerName: String
    public let employerColour: EmployerColour

    public var id: Shift.ID { shift.id }

    init(shift: Shift, employer: Employer?) {
        self.shift = shift
        employerName = employer?.name ?? "Unknown employer"
        employerColour = employer?.colour ?? .violet
    }
}
