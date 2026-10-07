import Foundation

/// Runs the use case behind a shift prompt's button, whether the student tapped it on the
/// expanded prompt (notification extension) or on the banner (the app, in the background).
public struct ShiftPromptResponder: Sendable {
    private let services: FortnightlyServices

    public init(services: FortnightlyServices) {
        self.services = services
    }

    /// What happened, in one sentence the prompt can show: "Clocked in at 5:00 pm."
    public func respond(to action: ShiftPromptAction, shiftID: Shift.ID) throws -> String {
        switch action {
        case .startedOnTime:
            return clockedIn(try services.clockIntoShift.execute(shiftID: shiftID, startedAt: .asRostered))
        case .startedJustNow:
            return clockedIn(try services.clockIntoShift.execute(shiftID: shiftID, startedAt: .now))
        case .notWorking:
            try services.markShiftNotWorked.execute(shiftID: shiftID)
            return "Marked as not working. Its hours no longer count."
        case .finishedOnTime:
            return clockedOut(try services.clockOutOfShift.execute(shiftID: shiftID, finishedAt: .asRostered))
        case .finishedJustNow:
            return clockedOut(try services.clockOutOfShift.execute(shiftID: shiftID, finishedAt: .now))
        case .stillWorking:
            guard let shift = try services.shifts.shift(withID: shiftID) else { throw ClockOutOfShiftError.shiftNotFound }
            let employerName = try services.employers.employer(withID: shift.employerID)?.name ?? "your shift"
            let askAgainAt = services.currentTime.addingTimeInterval(ShiftPromptAction.snoozeMinutes * 60)
            services.reminders.snoozeClockOutReminder(for: shift, employerName: employerName, until: askAgainAt)
            return "We'll ask again at \(askAgainAt.formatted(date: .omitted, time: .shortened))."
        }
    }

    private func clockedIn(_ shift: Shift) -> String {
        "Clocked in at \((shift.clockedInAt ?? shift.rosteredStart).formatted(date: .omitted, time: .shortened))."
    }

    /// A breach is recorded, never refused, so the student is told about it straight away.
    private func clockedOut(_ outcome: WorkedShiftOutcome) -> String {
        let finishedAt = (outcome.workedShift.clockedOutAt ?? outcome.workedShift.rosteredFinish).formatted(date: .omitted, time: .shortened)
        guard let over = outcome.fortnightsOverLimit.first else { return "Clocked out at \(finishedAt)." }
        return "Clocked out at \(finishedAt). \(over.fortnight.datesDescription) is now over the \(WorkLimitPolicy.hoursPerFortnight.hoursDescription)-hour limit."
    }
}
