import Foundation

public protocol CourseBreakRepository: Sendable {
    /// Breaks with at least one day inside `interval`.
    func courseBreaks(overlapping interval: DateInterval) throws -> [CourseBreak]
    /// Every recorded break, earliest first.
    func allCourseBreaks() throws -> [CourseBreak]
    func save(_ courseBreak: CourseBreak) throws
    func remove(_ id: CourseBreak.ID) throws
}
