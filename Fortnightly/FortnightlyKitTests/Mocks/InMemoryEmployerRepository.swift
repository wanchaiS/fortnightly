import Foundation
@testable import FortnightlyKit

final class InMemoryEmployerRepository: EmployerRepository, @unchecked Sendable {
    private(set) var savedEmployers: [Employer]

    init(_ employers: Employer...) {
        savedEmployers = employers
    }

    func employers(includingArchived: Bool) throws -> [Employer] {
        savedEmployers.filter { includingArchived || !$0.isArchived }
    }

    func employer(withID id: Employer.ID) throws -> Employer? {
        savedEmployers.first { $0.id == id }
    }

    func save(_ employer: Employer) throws {
        if let index = savedEmployers.firstIndex(where: { $0.id == employer.id }) {
            savedEmployers[index] = employer
        } else {
            savedEmployers.append(employer)
        }
    }
}
