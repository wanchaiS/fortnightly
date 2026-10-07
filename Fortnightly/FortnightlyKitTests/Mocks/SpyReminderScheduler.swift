import Foundation
@testable import FortnightlyKit

/// Records which shifts the student would get clock-in and clock-out prompts for.
final class SpyReminderScheduler: ShiftReminderScheduling, @unchecked Sendable {
    private(set) var scheduledShiftIDs: [Shift.ID] = []
    private(set) var clockInRemindersCancelledFor: [Shift.ID] = []
    private(set) var allRemindersCancelledFor: [Shift.ID] = []
    private(set) var reminderWindow: [ShiftReminder] = []

    func scheduleReminders(for shift: Shift, employerName: String) {
        scheduledShiftIDs.append(shift.id)
    }

    func cancelClockInReminders(for shiftID: Shift.ID) {
        clockInRemindersCancelledFor.append(shiftID)
    }

    func cancelAllReminders(for shiftID: Shift.ID) {
        allRemindersCancelledFor.append(shiftID)
    }

    func replaceAllReminders(with reminders: [ShiftReminder]) {
        reminderWindow = reminders
    }
}

/// Widget reloads aren't asserted: they're platform plumbing.
struct IgnoredDisplayRefresh: ShiftDisplayRefreshing {
    func shiftsDidChange() {}
}
