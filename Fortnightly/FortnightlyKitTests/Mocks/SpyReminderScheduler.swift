import Foundation
@testable import FortnightlyKit

/// Records which shifts the student would get clock-in and clock-out prompts for.
final class SpyReminderScheduler: ShiftReminderScheduling, @unchecked Sendable {
    private(set) var scheduledShiftIDs: [Shift.ID] = []

    func scheduleReminders(for shift: Shift, employerName: String) {
        scheduledShiftIDs.append(shift.id)
    }
}

/// Widget reloads aren't asserted: they're platform plumbing.
struct IgnoredDisplayRefresh: ShiftDisplayRefreshing {
    func shiftsDidChange() {}
}
