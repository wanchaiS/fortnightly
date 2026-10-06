import FortnightlyKit
import Foundation
import Observation
import SwiftUI
import UserNotifications

@MainActor
@Observable
final class ShiftPromptModel {
    enum State {
        case loading
        case shift(employerName: String, rosteredStart: Date, rosteredFinish: Date, isStartPrompt: Bool)
        case unavailable(String)
    }

    private(set) var state: State = .loading

    func load(_ content: UNNotificationContent) {
        guard let rawID = content.userInfo[ShiftPromptCategory.shiftIDKey] as? String, let shiftID = UUID(uuidString: rawID) else {
            state = .unavailable("This reminder isn't linked to a shift. Open Fortnightly to check your roster.")
            return
        }
        do {
            let store = try ShiftStore.appGroup.get()
            guard let shift = try CoreDataShiftRepository(store: store).shift(withID: shiftID) else {
                state = .unavailable("This shift is no longer on your roster. Open Fortnightly to check your upcoming shifts.")
                return
            }
            let employerName = try CoreDataEmployerRepository(store: store).employer(withID: shift.employerID)?.name
            state = .shift(
                employerName: employerName ?? "Unknown employer",
                rosteredStart: shift.rosteredStart,
                rosteredFinish: shift.rosteredFinish,
                isStartPrompt: content.categoryIdentifier == ShiftPromptCategory.shiftStart
            )
        } catch {
            state = .unavailable("Your shifts couldn't be loaded here. Open Fortnightly to clock in or out.")
        }
    }
}

struct ShiftPromptView: View {
    let prompt: ShiftPromptModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch prompt.state {
            case .loading:
                ProgressView()
            case let .shift(employerName, rosteredStart, rosteredFinish, isStartPrompt):
                Text(isStartPrompt ? "Shift starting" : "Shift finishing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(employerName)
                    .font(.title3.bold())
                Text("Rostered \(rosteredStart.formatted(date: .omitted, time: .shortened)) – \(rosteredFinish.formatted(date: .omitted, time: .shortened))")
                Text(isStartPrompt ? "Have you started? Clock in so this fortnight's hours stay accurate." : "Have you finished? Clock out with the time you actually stopped.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            case let .unavailable(message):
                Text(message)
                    .font(.footnote)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
