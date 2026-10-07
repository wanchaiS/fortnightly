import Foundation

public protocol ShiftRepository: Sendable {
    func shift(withID id: Shift.ID) throws -> Shift?
    /// Rostered shifts that haven't finished yet, earliest first.
    func upcomingShifts(after date: Date) throws -> [Shift]
    /// Rostered, on-shift and worked shifts whose time falls at least partly inside `interval`.
    func shiftsCountingTowardWorkLimit(overlapping interval: DateInterval) throws -> [Shift]
    func save(_ shift: Shift) throws
}
