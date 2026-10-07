import FortnightlyKit
import Foundation
import Observation

@Observable
final class FortnightBoardModel {
    struct Fortnight: Identifiable {
        let summary: FortnightWorkSummary
        let days: [WorkDay]

        var id: Date { summary.fortnight.startsOn }
        var hasShifts: Bool { days.contains { !$0.shifts.isEmpty } }
    }

    /// The two work fortnights containing today: the one that started last Monday, then this Monday's.
    private(set) var fortnights: [Fortnight] = []
    var selectedIndex = 0
    private(set) var employers: [Employer] = []
    private(set) var currentShift: CurrentShift = .nothingRostered
    private(set) var missedShifts: [ShiftListing] = []
    private(set) var now = Date()
    var problem: ProblemMessage?

    let services: FortnightlyServices
    let actions: ShiftActions

    init(services: FortnightlyServices) {
        self.services = services
        actions = ShiftActions(services: services)
        actions.onChange = { [weak self] in self?.refresh() }
    }

    var selected: Fortnight? { fortnights.indices.contains(selectedIndex) ? fortnights[selectedIndex] : nil }

    /// A fortnight containing today that is already over the limit, for the dock to mention.
    var fortnightOverLimit: FortnightWorkSummary? {
        fortnights.map(\.summary).first { $0.status == .overLimit }
    }

    func refresh() {
        do {
            now = services.currentTime
            let review = try services.reviewFortnightHours.execute(on: now)
            fortnights = try [review.fortnightStartedLastWeek, review.fortnightStartingThisWeek].map { summary in
                Fortnight(summary: summary, days: try services.reviewFortnightDays.execute(for: summary.fortnight))
            }
            employers = try services.reviewJobs.execute().allEmployers
            currentShift = try services.reviewCurrentShift.execute()
            missedShifts = try services.reviewMissedShifts.execute()
        } catch {
            problem = ProblemMessage(error)
        }
    }

    /// Prompts for the next shifts, rebuilt whenever the app comes to the front.
    func refreshReminders() {
        do {
            try services.refreshShiftReminders.execute()
        } catch {
            problem = ProblemMessage(error)
        }
    }
}
