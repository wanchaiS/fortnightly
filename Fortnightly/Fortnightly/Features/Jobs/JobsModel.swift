import FortnightlyKit
import Foundation
import Observation

@Observable
final class JobsModel {
    private(set) var employers: [Employer] = []
    private(set) var archivedEmployers: [Employer] = []
    private(set) var courseBreaks: [CourseBreak] = []
    var problem: ProblemMessage?

    private let services: FortnightlyServices

    init(services: FortnightlyServices) {
        self.services = services
    }

    func load() {
        perform {
            let jobs = try services.reviewJobs.execute()
            employers = jobs.employers
            archivedEmployers = jobs.archivedEmployers
            courseBreaks = jobs.courseBreaks
        }
    }

    // The forms show their own errors, so these throw.

    func saveEmployer(_ details: EmployerDetails) throws {
        try services.addEmployer.execute(details)
    }

    func archive(_ employer: Employer) throws {
        try services.archiveEmployer.execute(employerID: employer.id)
    }

    func saveCourseBreak(_ details: CourseBreakDetails) throws {
        try services.recordCourseBreak.execute(details)
    }

    func remove(_ courseBreak: CourseBreak) {
        perform { try services.removeCourseBreak.execute(courseBreakID: courseBreak.id) }
        load()
    }

    #if DEBUG
    func loadSampleRoster() {
        perform { try services.loadSampleRoster() }
        load()
    }
    #endif

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            problem = ProblemMessage(error)
        }
    }
}
