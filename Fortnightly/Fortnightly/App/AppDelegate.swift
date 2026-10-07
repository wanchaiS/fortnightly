import FortnightlyKit
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories(ShiftPromptCategory.all)
        return true
    }

    /// Show shift prompts as banners even while Fortnightly is open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// A button on a shift prompt's banner. The expanded prompt handles its own buttons.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let action = ShiftPromptAction(rawValue: response.actionIdentifier),
              let rawID = response.notification.request.content.userInfo[ShiftPromptCategory.shiftIDKey] as? String,
              let shiftID = UUID(uuidString: rawID),
              let services = try? AppServices.shared.get()
        else { return }
        do {
            _ = try ShiftPromptResponder(services: services).respond(to: action, shiftID: shiftID)
        } catch {
            await tellStudent(about: error)
        }
    }

    /// The button ran in the background, so the problem can only reach the student as another notification.
    private func tellStudent(about error: Error) async {
        let content = UNMutableNotificationContent()
        content.title = error.localizedDescription
        content.body = (error as? LocalizedError)?.recoverySuggestion ?? "Open Fortnightly to check your shift."
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "shift.problem", content: content, trigger: nil))
    }
}
