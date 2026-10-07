import UserNotifications

/// Notification categories handled by the ShiftPromptNotification content extension.
/// Must match `UNNotificationExtensionCategory` in that extension's Info.plist.
public enum ShiftPromptCategory {
    public static let shiftStart = "SHIFT_START"
    public static let shiftFinish = "SHIFT_FINISH"

    /// `userInfo` key carrying the prompted shift's UUID string.
    public static let shiftIDKey = "shiftID"

    public static var all: Set<UNNotificationCategory> {
        [
            UNNotificationCategory(
                identifier: shiftStart,
                actions: [ShiftPromptAction.startedOnTime, .startedJustNow, .notWorking].map { $0.notificationAction() },
                intentIdentifiers: []
            ),
            UNNotificationCategory(
                identifier: shiftFinish,
                actions: [ShiftPromptAction.finishedOnTime, .finishedJustNow, .stillWorking].map { $0.notificationAction() },
                intentIdentifiers: []
            ),
        ]
    }
}

/// The buttons under a shift prompt. They run in the background, through the same use cases as the app.
public enum ShiftPromptAction: String, CaseIterable, Sendable {
    case startedOnTime
    case startedJustNow
    case notWorking
    case finishedOnTime
    case finishedJustNow
    case stillWorking

    public static let snoozeMinutes: Double = 30

    /// With the shift's real times when known, as the expanded prompt shows them: "Started 5:00 pm".
    public func title(for shift: Shift? = nil) -> String {
        switch self {
        case .startedOnTime: shift.map { "Started \($0.rosteredStart.formatted(date: .omitted, time: .shortened))" } ?? "Started on time"
        case .startedJustNow: "Started just now"
        case .notWorking: "Not working this shift"
        case .finishedOnTime: shift.map { "Finished \($0.rosteredFinish.formatted(date: .omitted, time: .shortened))" } ?? "Finished on time"
        case .finishedJustNow: "Finished just now"
        case .stillWorking: "Still working, remind me in 30 min"
        }
    }

    public func notificationAction(for shift: Shift? = nil) -> UNNotificationAction {
        UNNotificationAction(identifier: rawValue, title: title(for: shift), options: self == .notWorking ? [.destructive] : [])
    }
}
