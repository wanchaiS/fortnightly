import FortnightlyKit
import Foundation
import Observation

/// Clocking in and out and marking a shift not worked, from the dock or a shift's details.
/// A clock-out that breaches the limit is recorded without a pop-up: the board turns the hours line red.
@Observable
final class ShiftActions {
    var problem: ProblemMessage?
    /// Called after a change is saved, so the screen showing the shift can reload or close.
    var onChange: () -> Void = {}
    private let services: FortnightlyServices

    init(services: FortnightlyServices) {
        self.services = services
    }

    func clockIn(_ shift: Shift, startedAt time: ClockInTime) {
        perform { _ = try services.clockIntoShift.execute(shiftID: shift.id, startedAt: time) }
    }

    func clockOut(_ shift: Shift, finishedAt time: ClockOutTime) {
        perform { _ = try services.clockOutOfShift.execute(shiftID: shift.id, finishedAt: time) }
    }

    func markNotWorked(_ shift: Shift) {
        perform { try services.markShiftNotWorked.execute(shiftID: shift.id) }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            onChange()
        } catch {
            problem = ProblemMessage(error)
        }
    }
}
