import Foundation

public protocol ShiftRepository: Sendable {
    func shift(withID id: Shift.ID) throws -> Shift?
    /// The shift the student is clocked into right now, if any.
    func openShift() throws -> Shift?
    /// Rostered shifts that haven't finished yet, earliest first.
    func upcomingShifts(after date: Date) throws -> [Shift]
    /// Every shift still waiting for a clock-in, earliest first: upcoming ones and any that finished without one.
    func rosteredShifts() throws -> [Shift]
    /// Rostered, on-shift and worked shifts whose time falls at least partly inside `interval`.
    func shiftsCountingTowardWorkLimit(overlapping interval: DateInterval) throws -> [Shift]
    func save(_ shift: Shift) throws
}
