import FortnightlyKit
import Foundation
import Observation
import SwiftUI
import UserNotifications

@MainActor
@Observable
final class ShiftPromptModel {
    struct Prompt {
        let listing: ShiftListing
        let isStartPrompt: Bool
        let fortnight: FortnightWorkSummary
        let slices: [DonutSlice]
        let day: WorkDay?
        /// Set when the shift was already dealt with elsewhere (the app or the widget).
        let alreadyDone: String?
    }

    enum State {
        case loading
        case prompt(Prompt)
        case finished(String)
        case unavailable(ProblemText)
    }

    struct ProblemText {
        let title: String
        let message: String

        init(_ error: Error) {
            title = error.localizedDescription
            message = (error as? LocalizedError)?.recoverySuggestion ?? ""
        }
    }

    private(set) var state: State = .loading
    /// Shown above the prompt when a button failed, so the student can try another one.
    private(set) var problem: ProblemText?
    private(set) var shiftID: Shift.ID?

    /// The buttons that make sense for this shift now; none once it's already dealt with.
    var actions: [ShiftPromptAction] {
        guard case let .prompt(prompt) = state, prompt.alreadyDone == nil else { return [] }
        return prompt.isStartPrompt ? [.startedOnTime, .startedJustNow, .notWorking] : [.finishedOnTime, .finishedJustNow, .stillWorking]
    }

    func load(_ content: UNNotificationContent) {
        guard let rawID = content.userInfo[ShiftPromptCategory.shiftIDKey] as? String, let id = UUID(uuidString: rawID) else {
            state = .unavailable(ProblemText(ReviewShiftError.shiftNotFound))
            return
        }
        shiftID = id
        do {
            let services = try FortnightlyServices.appGroup()
            let listing = try services.reviewShift.execute(shiftID: id)
            let shift = listing.shift
            let review = try services.reviewFortnightHours.execute(on: shift.rosteredStart)
            // Of the two fortnights the shift falls in, show the one closer to the limit.
            let fortnight = [review.fortnightStartedLastWeek, review.fortnightStartingThisWeek].max { $0.hoursTowardLimit < $1.hoursTowardLimit }!
            let days = try services.reviewFortnightDays.execute(for: fortnight.fortnight)
            let isStartPrompt = content.categoryIdentifier == ShiftPromptCategory.shiftStart
            state = .prompt(Prompt(
                listing: listing,
                isStartPrompt: isStartPrompt,
                fortnight: fortnight,
                slices: DonutSlice.slices(for: fortnight, employers: try services.reviewJobs.execute().allEmployers),
                day: days.first { $0.shifts.contains { $0.id == id } },
                alreadyDone: Self.alreadyDone(shift, isStartPrompt: isStartPrompt)
            ))
        } catch {
            state = .unavailable(ProblemText(error))
        }
    }

    /// Runs the button through the same use case the app uses. Returns whether the prompt can close.
    func respond(to action: ShiftPromptAction) -> Bool {
        guard let shiftID else { return true }
        do {
            let services = try FortnightlyServices.appGroup()
            state = .finished(try ShiftPromptResponder(services: services).respond(to: action, shiftID: shiftID))
            problem = nil
            return true
        } catch {
            problem = ProblemText(error)
            return false
        }
    }

    private static func alreadyDone(_ shift: Shift, isStartPrompt: Bool) -> String? {
        switch shift.status {
        case .notWorked:
            return "You marked this shift as not working."
        case .worked:
            return "Already clocked out at \((shift.clockedOutAt ?? shift.rosteredFinish).formatted(date: .omitted, time: .shortened))."
        case .onShift where isStartPrompt:
            return "Already clocked in at \((shift.clockedInAt ?? shift.rosteredStart).formatted(date: .omitted, time: .shortened))."
        case .rostered where !isStartPrompt:
            return "You didn't clock in to this shift. Open Fortnightly to enter your times or mark it as not working."
        default:
            return nil
        }
    }
}

struct ShiftPromptView: View {
    let prompt: ShiftPromptModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let problem = prompt.problem {
                message(problem.title, problem.message)
            }
            switch prompt.state {
            case .loading:
                ProgressView()
            case let .prompt(details):
                promptBody(details)
            case let .finished(text):
                Label(text, systemImage: "checkmark.circle.fill")
                    .font(.headline)
            case let .unavailable(problem):
                message(problem.title, problem.message)
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.ground)
    }

    private func promptBody(_ details: ShiftPromptModel.Prompt) -> some View {
        let shift = details.listing.shift
        let time = details.isStartPrompt ? shift.rosteredStart : shift.rosteredFinish
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                FortnightDonut(slices: details.slices, lineWidth: 9)
                    .frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(details.listing.employerName) \(details.isStartPrompt ? "started" : "finished") at \(time.formatted(date: .omitted, time: .shortened))")
                        .font(.headline)
                    Group {
                        Text("Rostered \(shift.rosteredStart.formatted(date: .omitted, time: .shortened)) – \(shift.rosteredFinish.formatted(date: .omitted, time: .shortened))")
                        Text("\(details.fortnight.hoursTowardLimit.hoursDescription) of \(WorkLimitPolicy.hoursPerFortnight.hoursDescription) h this fortnight")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .monospacedDigit()
                }
            }
            if let day = details.day {
                DayRow(
                    date: day.date,
                    segments: day.shifts.map { DayBarSegment(listing: $0, now: .now) },
                    hours: day.hours,
                    isToday: Calendar.current.isDateInToday(day.date)
                )
                .padding(.horizontal, 12)
                .background(Palette.card, in: .rect(cornerRadius: 12))
            }
            if details.fortnight.status == .overLimit {
                Text("\(details.fortnight.fortnight.datesDescription) is over the \(WorkLimitPolicy.hoursPerFortnight.hoursDescription)-hour limit.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(details.fortnight.status.color)
            }
            if let alreadyDone = details.alreadyDone {
                Text(alreadyDone).font(.subheadline)
            }
        }
    }

    private func message(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(text).font(.subheadline)
        }
    }
}
