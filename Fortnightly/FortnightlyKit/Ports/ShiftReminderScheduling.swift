/// Schedules the clock-in and clock-out prompts for a shift (implemented with local notifications).
public protocol ShiftReminderScheduling: Sendable {
    func scheduleReminders(for shift: Shift, employerName: String)
    /// The student has clocked in, so the "shift started, not clocked in" prompts no longer apply.
    func cancelClockInReminders(for shiftID: Shift.ID)
    /// The shift is over (clocked out or not worked), so none of its prompts apply.
    func cancelAllReminders(for shiftID: Shift.ID)
}
