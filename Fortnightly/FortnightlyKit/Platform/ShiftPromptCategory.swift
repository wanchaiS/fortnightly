import UserNotifications

/// Notification categories handled by the ShiftPromptNotification content extension.
/// Must match `UNNotificationExtensionCategory` in that extension's Info.plist.
public enum ShiftPromptCategory {
    public static let shiftStart = "SHIFT_START"
    public static let shiftFinish = "SHIFT_FINISH"

    /// `userInfo` key carrying the prompted shift's UUID string.
    public static let shiftIDKey = "shiftID"

    /// Registered by the app at launch. Clock-in/out actions are added with the notification feature.
    public static var all: Set<UNNotificationCategory> {
        [
            UNNotificationCategory(identifier: shiftStart, actions: [], intentIdentifiers: []),
            UNNotificationCategory(identifier: shiftFinish, actions: [], intentIdentifiers: []),
        ]
    }
}
