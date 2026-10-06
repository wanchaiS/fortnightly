public protocol EmployerRepository: Sendable {
    func employers(includingArchived: Bool) throws -> [Employer]
    func employer(withID id: Employer.ID) throws -> Employer?
    func save(_ employer: Employer) throws
}
