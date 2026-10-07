import Foundation

public protocol CourseBreakRepository: Sendable {
    func courseBreaks(overlapping interval: DateInterval) throws -> [CourseBreak]
}
