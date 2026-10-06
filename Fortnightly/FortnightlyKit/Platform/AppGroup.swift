import Foundation

/// The shared container the app, the widget and the notification extension all read and write.
public enum AppGroup {
    public static let identifier = "group.com.peter.fortnightly"

    /// `nil` when the target is missing the App Groups entitlement.
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    /// Small key-value values shared across processes (not domain data — that lives in Core Data).
    public static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}
