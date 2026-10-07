import Foundation
import UserNotifications

/// Shift prompts as local notifications. Works from the app and both extensions: they share the app's pending list.
public struct NotificationReminderScheduler: ShiftReminderScheduling {
    public init() {}

    private var center: UNUserNotificationCenter { .current() }

    public func scheduleReminders(for shift: Shift, employerName: String) {
        add(shift.reminders(employerName: employerName, after: .now))
    }

    public func cancelClockInReminders(for shiftID: Shift.ID) {
        remove([.clockInDue, .clockInOverdue], of: shiftID)
    }

    public func cancelAllReminders(for shiftID: Shift.ID) {
        remove([.clockInDue, .clockInOverdue, .clockOutDue, .clockOutOverdue], of: shiftID)
    }

    public func replaceAllReminders(with reminders: [ShiftReminder]) {
        center.removeAllPendingNotificationRequests()
        add(reminders)
    }

    public func snoozeClockOutReminder(for shift: Shift, employerName: String, until date: Date) {
        add([ShiftReminder(shiftID: shift.id, moment: .clockOutOverdue, firesAt: date, employerName: employerName)])
    }

    private func add(_ reminders: [ShiftReminder]) {
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            content.categoryIdentifier = reminder.isAboutClockingIn ? ShiftPromptCategory.shiftStart : ShiftPromptCategory.shiftFinish
            content.userInfo = [ShiftPromptCategory.shiftIDKey: reminder.shiftID.uuidString]
            let when = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.firesAt)
            // A request with an existing identifier replaces the pending one, so rescheduling never duplicates.
            center.add(UNNotificationRequest(
                identifier: reminder.identifier,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
            ))
        }
    }

    private func remove(_ moments: [ShiftReminder.Moment], of shiftID: Shift.ID) {
        let identifiers = moments.map { ShiftReminder.identifier(shiftID: shiftID, moment: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}

private extension ShiftReminder {
    var isAboutClockingIn: Bool { moment == .clockInDue || moment == .clockInOverdue }

    var title: String {
        switch moment {
        case .clockInDue: "\(employerName) shift starting"
        case .clockInOverdue: "Not clocked in at \(employerName)"
        case .clockOutDue: "\(employerName) shift finishing"
        case .clockOutOverdue: "Still clocked in at \(employerName)"
        }
    }

    var body: String {
        switch moment {
        case .clockInDue, .clockInOverdue: "Did you start on time? Clock in so your hours are recorded."
        case .clockOutDue, .clockOutOverdue: "Did you finish on time? Clock out with the time you stopped."
        }
    }
}
