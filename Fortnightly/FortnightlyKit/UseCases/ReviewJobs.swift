import Foundation

public enum ReviewJobsError: Error, Equatable {
    case recordsUnavailable
}

extension ReviewJobsError: LocalizedError {
    public var errorDescription: String? {
        "Your jobs couldn't be loaded right now."
    }

    public var recoverySuggestion: String? {
        "Your shifts are safe. Close and reopen Fortnightly."
    }
}

public struct JobsOverview: Equatable, Sendable {
    public let employers: [Employer]
    /// Still needed to name and colour the hours worked there.
    public let archivedEmployers: [Employer]
    public let courseBreaks: [CourseBreak]

    public var allEmployers: [Employer] { employers + archivedEmployers }
}

public struct ReviewJobs: Sendable {
    private let employers: any EmployerRepository
    private let courseBreaks: any CourseBreakRepository

    public init(employers: any EmployerRepository, courseBreaks: any CourseBreakRepository) {
        self.employers = employers
        self.courseBreaks = courseBreaks
    }

    public func execute() throws(ReviewJobsError) -> JobsOverview {
        do {
            let all = try employers.employers(includingArchived: true)
            return JobsOverview(
                employers: all.filter { !$0.isArchived },
                archivedEmployers: all.filter(\.isArchived),
                courseBreaks: try courseBreaks.allCourseBreaks()
            )
        } catch {
            throw .recordsUnavailable
        }
    }
}
