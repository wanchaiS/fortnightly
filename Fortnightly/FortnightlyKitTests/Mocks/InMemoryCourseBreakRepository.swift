import Foundation
@testable import FortnightlyKit

/// Returns every stored break; the use case decides which days they cover.
final class InMemoryCourseBreakRepository: CourseBreakRepository, @unchecked Sendable {
    private(set) var savedCourseBreaks: [CourseBreak] = []

    func add(_ courseBreak: CourseBreak) {
        savedCourseBreaks.append(courseBreak)
    }

    func courseBreaks(overlapping interval: DateInterval) throws -> [CourseBreak] {
        savedCourseBreaks
    }
}
