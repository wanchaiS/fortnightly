import FortnightlyKit
import SwiftUI

struct ContentView: View {
    @AppStorage(OnboardingProgress.doneKey) private var onboardingDone = false

    var body: some View {
        switch AppServices.shared {
        case let .success(services):
            if onboardingDone {
                FortnightBoardView(services: services)
            } else {
                OnboardingView(services: services) { onboardingDone = true }
            }
        case .failure:
            ContentUnavailableView(
                "Your shifts can't be opened",
                systemImage: "exclamationmark.triangle",
                description: Text("Fortnightly couldn't open its storage on this phone. Restart your phone, then open Fortnightly again.")
            )
        }
    }
}

enum OnboardingProgress {
    static let doneKey = "onboardingDone"
}
