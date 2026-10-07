import Foundation

/// When the student says they started work.
public enum ClockInTime: Equatable, Sendable {
    /// "Started on time": the rostered start, even if they confirm later.
    case asRostered
    /// "Started just now".
    case now
    case at(Date)
}

public enum ClockIntoShiftError: Error, Equatable {
    case shiftNotFound
    case alreadyClockedIn(since: Date)
    case alreadyFinished
    case markedNotWorked
    case anotherShiftInProgress(employerName: String, since: Date)
    case tooEarly(rosteredStart: Date)
    case afterRosteredFinish(rosteredFinish: Date)
    case timeInFuture
    case recordsUnavailable
}

extension ClockIntoShiftError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .shiftNotFound:
            "This shift is no longer on your roster."
        case let .alreadyClockedIn(since):
            "You clocked in to this shift at \(since.formatted(date: .omitted, time: .shortened))."
        case .alreadyFinished:
            "You've already clocked out of this shift."
        case .markedNotWorked:
            "You marked this shift as not worked."
        case let .anotherShiftInProgress(employerName, since):
            "You're still clocked in at \(employerName) (since \(since.formatted(date: .omitted, time: .shortened)))."
        case let .tooEarly(rosteredStart):
            "This shift isn't rostered to start until \(rosteredStart.formatted(date: .omitted, time: .shortened))."
        case let .afterRosteredFinish(rosteredFinish):
            "That's after this shift was rostered to finish (\(rosteredFinish.formatted(date: .omitted, time: .shortened)))."
        case .timeInFuture:
            "You can't clock in at a time that hasn't happened yet."
        case .recordsUnavailable:
            "Your clock-in couldn't be saved."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .shiftNotFound:
            "Check your upcoming shifts in Roster."
        case .alreadyClockedIn:
            "Nothing to do: your hours are being tracked."
        case .alreadyFinished:
            "If the times are wrong, correct them from the shift's details."
        case .markedNotWorked:
            "If you did work it, restore it from the shift's details."
        case .anotherShiftInProgress:
            "Clock out of that shift first, then clock in here."
        case .tooEarly:
            "You can clock in up to \(Int(ClockIntoShift.earliestClockInMinutesBeforeStart)) minutes early. If your start time changed, edit the shift first."
        case .afterRosteredFinish:
            "Choose \"Started on time\", or edit the shift if it was moved."
        case .timeInFuture:
            "Choose \"Started just now\"."
        case .recordsUnavailable:
            "Try again. If it keeps failing, note your start time and add it later with Log a past shift."
        }
    }
}

/// Records that the student has started a rostered shift.
public struct ClockIntoShift: Sendable {
    /// Clocking in earlier than this before the rostered start usually means the wrong shift.
    public static let earliestClockInMinutesBeforeStart: Double = 60

    private let shifts: any ShiftRepository
    private let employers: any EmployerRepository
    private let reminders: any ShiftReminderScheduling
    private let display: any ShiftDisplayRefreshing
    private let now: @Sendable () -> Date

    public init(
        shifts: any ShiftRepository,
        employers: any EmployerRepository,
        reminders: any ShiftReminderScheduling,
        display: any ShiftDisplayRefreshing,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.shifts = shifts
        self.employers = employers
        self.reminders = reminders
        self.display = display
        self.now = now
    }

    /// Marks the shift as on shift from the chosen start time, then stops its clock-in prompts and refreshes the widget.
    @discardableResult
    public func execute(shiftID: Shift.ID, startedAt time: ClockInTime) throws(ClockIntoShiftError) -> Shift {
        let currentTime = now()
        guard var shift = try read({ try shifts.shift(withID: shiftID) }) else { throw .shiftNotFound }
        switch shift.status {
        case .rostered: break
        case .onShift: throw .alreadyClockedIn(since: shift.clockedInAt ?? shift.rosteredStart)
        case .worked: throw .alreadyFinished
        case .notWorked: throw .markedNotWorked
        }
        if let openShift = try read({ try shifts.openShift() }) {
            let employerName = try read { try employers.employer(withID: openShift.employerID)?.name }
            throw .anotherShiftInProgress(employerName: employerName ?? "another job", since: openShift.clockedInAt ?? openShift.rosteredStart)
        }

        let startedAt = switch time {
        case .asRostered: shift.rosteredStart
        case .now: currentTime
        case let .at(date): date
        }
        guard startedAt <= currentTime else { throw .timeInFuture }
        guard startedAt >= shift.rosteredStart.addingTimeInterval(-Self.earliestClockInMinutesBeforeStart * 60) else {
            throw .tooEarly(rosteredStart: shift.rosteredStart)
        }
        guard startedAt < shift.rosteredFinish else { throw .afterRosteredFinish(rosteredFinish: shift.rosteredFinish) }

        shift.clockedInAt = startedAt
        shift.status = .onShift
        try read { try shifts.save(shift) }
        reminders.cancelClockInReminders(for: shift.id)
        display.shiftsDidChange()
        return shift
    }

    private func read<Value>(_ operation: () throws -> Value) throws(ClockIntoShiftError) -> Value {
        do {
            return try operation()
        } catch {
            throw .recordsUnavailable
        }
    }
}
