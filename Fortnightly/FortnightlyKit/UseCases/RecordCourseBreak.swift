import Foundation

public struct CourseBreakDetails: Sendable {
    public var name: String
    public var startsOn: Date
    /// The last day of the break; it's part of the break.
    public var endsOn: Date
    /// `nil` adds a new break.
    public var editing: CourseBreak.ID?

    public init(name: String, startsOn: Date, endsOn: Date, editing: CourseBreak.ID? = nil) {
        self.name = name
        self.startsOn = startsOn
        self.endsOn = endsOn
        self.editing = editing
    }
}

public enum RecordCourseBreakError: Error, Equatable {
    case endsBeforeItStarts
    case unrealisticallyLong(days: Int)
    case overlaps(CourseBreak)
    case recordsUnavailable
}

extension RecordCourseBreakError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .endsBeforeItStarts:
            "This break ends before it starts."
        case let .unrealisticallyLong(days):
            "That break is \(days) days long."
        case let .overlaps(existing):
            "This overlaps \(existing.name) (\(existing.datesDescription))."
        case .recordsUnavailable:
            "This course break couldn't be saved."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .endsBeforeItStarts:
            "Check the first and last day of the break."
        case .unrealisticallyLong:
            "Check the year on the last day."
        case let .overlaps(existing):
            "Change the dates, or edit \(existing.name) instead."
        case .recordsUnavailable:
            "Your shifts are safe. Try again."
        }
    }
}

/// The work limit doesn't apply while the course isn't in session.
public struct RecordCourseBreak: Sendable {
    /// Longer than this almost always means the wrong year on the last day.
    public static let longestBreakDays = 130

    private let courseBreaks: any CourseBreakRepository
    private let display: any ShiftDisplayRefreshing
    private let calendar: Calendar

    public init(courseBreaks: any CourseBreakRepository, display: any ShiftDisplayRefreshing, calendar: Calendar = .current) {
        self.courseBreaks = courseBreaks
        self.display = display
        self.calendar = calendar
    }

    /// Breaks can't share a day: a break's last day belongs to it, so the next break starts the day after at the earliest.
    @discardableResult
    public func execute(_ details: CourseBreakDetails) throws(RecordCourseBreakError) -> CourseBreak {
        let firstDay = calendar.startOfDay(for: details.startsOn)
        let lastDay = calendar.startOfDay(for: details.endsOn)
        guard lastDay >= firstDay else { throw .endsBeforeItStarts }
        let days = calendar.dateComponents([.day], from: firstDay, to: lastDay).day! + 1
        guard days <= Self.longestBreakDays else { throw .unrealisticallyLong(days: days) }

        let name = details.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let courseBreak = CourseBreak(id: details.editing ?? UUID(), name: name.isEmpty ? "Course break" : name, startsOn: firstDay, endsOn: lastDay)
        let breakDays = courseBreak.interval(in: calendar)
        let otherBreaks = try read { try courseBreaks.allCourseBreaks() }.filter { $0.id != courseBreak.id }
        if let clash = otherBreaks.first(where: { $0.interval(in: calendar).overlaps(breakDays) }) {
            throw .overlaps(clash)
        }

        try read { try courseBreaks.save(courseBreak) }
        display.shiftsDidChange()
        return courseBreak
    }

    private func read<Value>(_ operation: () throws -> Value) throws(RecordCourseBreakError) -> Value {
        do {
            return try operation()
        } catch {
            throw .recordsUnavailable
        }
    }
}
