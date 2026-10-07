import Foundation

/// One clock-in or clock-out prompt for a shift.
public struct ShiftReminder: Equatable, Sendable {
    public enum Moment: String, Sendable {
        case clockInDue
        case clockInOverdue
        case clockOutDue
        case clockOutOverdue
    }

    public let shiftID: Shift.ID
    public let moment: Moment
    public let firesAt: Date
    public let employerName: String

    /// One identifier per prompt, so a prompt can be cancelled as soon as it no longer applies.
    public var identifier: String { "shift.\(shiftID.uuidString).\(moment.rawValue)" }
}

extension Shift {
    public static let clockInOverdueMinutes: Double = 20
    public static let clockOutOverdueMinutes: Double = 45

    /// The prompts this shift still needs after `now`: at the rostered start and finish, and again
    /// if the student hasn't clocked in or out a little later.
    public func reminders(employerName: String, after now: Date) -> [ShiftReminder] {
        let clockOut: [(ShiftReminder.Moment, Date)] = [
            (.clockOutDue, rosteredFinish),
            (.clockOutOverdue, rosteredFinish.addingTimeInterval(Self.clockOutOverdueMinutes * 60)),
        ]
        let moments: [(ShiftReminder.Moment, Date)] = switch status {
        case .rostered:
            [(.clockInDue, rosteredStart), (.clockInOverdue, rosteredStart.addingTimeInterval(Self.clockInOverdueMinutes * 60))] + clockOut
        case .onShift:
            clockOut
        case .worked, .notWorked:
            []
        }
        return moments
            .filter { $0.1 > now }
            .map { ShiftReminder(shiftID: id, moment: $0.0, firesAt: $0.1, employerName: employerName) }
    }
}
