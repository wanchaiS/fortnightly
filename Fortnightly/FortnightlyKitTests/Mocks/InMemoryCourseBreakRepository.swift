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

    func allCourseBreaks() throws -> [CourseBreak] {
        savedCourseBreaks.sorted { $0.startsOn < $1.startsOn }
    }

    func save(_ courseBreak: CourseBreak) throws {
        if let index = savedCourseBreaks.firstIndex(where: { $0.id == courseBreak.id }) {
            savedCourseBreaks[index] = courseBreak
        } else {
            savedCourseBreaks.append(courseBreak)
        }
    }

    func remove(_ id: CourseBreak.ID) throws {
        savedCourseBreaks.removeAll { $0.id == id }
    }
}
