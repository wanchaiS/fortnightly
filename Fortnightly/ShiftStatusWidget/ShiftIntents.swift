import AppIntents
import FortnightlyKit
import Foundation

/// The widget's clock-in buttons: "Started 5:00 pm" (the rostered time) and "Just now".
/// Both exist because a tap's time isn't necessarily when work started.
struct ClockInIntent: AppIntent {
    static let title: LocalizedStringResource = "Clock in"
    static let isDiscoverable = false

    @Parameter(title: "Shift") var shiftID: String
    @Parameter(title: "At the rostered start") var atRosteredStart: Bool

    init() {}

    init(shiftID: Shift.ID, atRosteredStart: Bool) {
        self.shiftID = shiftID.uuidString
        self.atRosteredStart = atRosteredStart
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: shiftID) else { return .result() }
        // A widget can't show an error; if this fails, the reloaded widget still shows the true state.
        _ = try? FortnightlyServices.appGroup().clockIntoShift.execute(shiftID: id, startedAt: atRosteredStart ? .asRostered : .now)
        return .result()
    }
}

struct ClockOutIntent: AppIntent {
    static let title: LocalizedStringResource = "Clock out"
    static let isDiscoverable = false

    @Parameter(title: "Shift") var shiftID: String
    @Parameter(title: "At the rostered finish") var atRosteredFinish: Bool

    init() {}

    init(shiftID: Shift.ID, atRosteredFinish: Bool) {
        self.shiftID = shiftID.uuidString
        self.atRosteredFinish = atRosteredFinish
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: shiftID) else { return .result() }
        // A widget can't show an error; if this fails, the reloaded widget still shows the true state.
        _ = try? FortnightlyServices.appGroup().clockOutOfShift.execute(shiftID: id, finishedAt: atRosteredFinish ? .asRostered : .now)
        return .result()
    }
}
