import Foundation

public enum RefreshShiftRemindersError: Error, Equatable {
    case recordsUnavailable
}

extension RefreshShiftRemindersError: LocalizedError {
    public var errorDescription: String? {
        "Your clock-in and clock-out reminders couldn't be updated."
    }

    public var recoverySuggestion: String? {
        "Open Fortnightly again later; until then, check the widget before and after each shift."
    }
}

/// Keeps prompts scheduled for the shift the student is on and the next shifts on the roster.
public struct RefreshShiftReminders: Sendable {
    /// iOS keeps at most 64 pending notifications per app; 10 shifts of up to 4 prompts stays well under.
    public static let shiftsAhead = 10

    private let shifts: any ShiftRepository
    private let employers: any EmployerRepository
    private let reminders: any ShiftReminderScheduling
    private let now: @Sendable () -> Date

    public init(
        shifts: any ShiftRepository,
        employers: any EmployerRepository,
        reminders: any ShiftReminderScheduling,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.shifts = shifts
        self.employers = employers
        self.reminders = reminders
        self.now = now
    }

    public func execute() throws(RefreshShiftRemindersError) {
        let currentTime = now()
        let window: [ShiftReminder]
        do {
            let open = try shifts.openShift()
            let upcoming = try shifts.upcomingShifts(after: currentTime).prefix(Self.shiftsAhead)
            window = try ([open].compactMap { $0 } + upcoming).flatMap { shift in
                let employerName = try employers.employer(withID: shift.employerID)?.name ?? "Your shift"
                return shift.reminders(employerName: employerName, after: currentTime)
            }
        } catch {
            throw .recordsUnavailable
        }
        reminders.replaceAllReminders(with: window)
    }
}
