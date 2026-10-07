/// Schedules the clock-in and clock-out prompts for a shift (implemented with local notifications).
public protocol ShiftReminderScheduling: Sendable {
    func scheduleReminders(for shift: Shift, employerName: String)
}
