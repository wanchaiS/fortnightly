import Foundation

public enum RemoveCourseBreakError: Error, Equatable {
    case recordsUnavailable
}

extension RemoveCourseBreakError: LocalizedError {
    public var errorDescription: String? {
        "This course break couldn't be removed."
    }

    public var recoverySuggestion: String? {
        "Your shifts are safe. Try again."
    }
}

/// Hours worked on the removed days count toward the limit again.
public struct RemoveCourseBreak: Sendable {
    private let courseBreaks: any CourseBreakRepository
    private let display: any ShiftDisplayRefreshing

    public init(courseBreaks: any CourseBreakRepository, display: any ShiftDisplayRefreshing) {
        self.courseBreaks = courseBreaks
        self.display = display
    }

    public func execute(courseBreakID: CourseBreak.ID) throws(RemoveCourseBreakError) {
        do {
            try courseBreaks.remove(courseBreakID)
        } catch {
            throw .recordsUnavailable
        }
        display.shiftsDidChange()
    }
}
