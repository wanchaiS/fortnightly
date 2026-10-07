import FortnightlyKit
import Foundation
import SwiftUI
import UIKit
import UserNotifications
import UserNotificationsUI

final class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private let prompt = ShiftPromptModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        let host = UIHostingController(rootView: ShiftPromptView(prompt: prompt))
        // The prompt grows to fit its content (a fixed height cut off the last line in the spike).
        host.sizingOptions = .preferredContentSize
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: any UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        preferredContentSize = CGSize(width: view.bounds.width, height: container.preferredContentSize.height)
    }

    func didReceive(_ notification: UNNotification) {
        prompt.load(notification.request.content)
        showActions()
    }

    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        guard let action = ShiftPromptAction(rawValue: response.actionIdentifier) else {
            completion(.dismissAndForwardAction)
            return
        }
        if prompt.respond(to: action) {
            extensionContext?.notificationActions = []
            // Leave "Clocked in at 5:00 pm." on screen for a moment before closing.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { completion(.dismiss) }
        } else {
            completion(.doNotDismiss)
        }
    }

    /// Buttons with the shift's real times ("Started 5:00 pm"), and none once the shift is dealt with.
    private func showActions() {
        guard case let .prompt(details) = prompt.state else {
            extensionContext?.notificationActions = []
            return
        }
        extensionContext?.notificationActions = prompt.actions.map { $0.notificationAction(for: details.listing.shift) }
    }
}
