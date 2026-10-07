import FortnightlyKit
import SwiftUI

@main struct FortnightlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        #if DEBUG
        // Launch with -sampleRoster to skip onboarding with two jobs and a fortnight of shifts (screenshots, marking).
        if CommandLine.arguments.contains("-sampleRoster"), let services = try? AppServices.shared.get() {
            try? services.loadSampleRoster()
            UserDefaults.standard.set(true, forKey: OnboardingProgress.doneKey)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
