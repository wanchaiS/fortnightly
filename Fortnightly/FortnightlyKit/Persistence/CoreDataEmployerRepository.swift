import CoreData
import Foundation

public struct CoreDataEmployerRepository: EmployerRepository, @unchecked Sendable {
    private let context: NSManagedObjectContext

    public init(store: ShiftStore) {
        context = store.makeContext()
    }

    public func employers(includingArchived: Bool) throws -> [Employer] {
        try context.performAndWait {
            let request = EmployerEntity.fetchRequest()
            if !includingArchived {
                request.predicate = NSPredicate(format: "isArchived == NO")
            }
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try context.fetchFresh(request).map { try $0.employer() }
        }
    }

    public func employer(withID id: Employer.ID) throws -> Employer? {
        try context.performAndWait {
            try EmployerEntity.find(id, in: context)?.employer()
        }
    }

    public func save(_ employer: Employer) throws {
        try context.performAndWait {
            let entity = try EmployerEntity.find(employer.id, in: context) ?? {
                let created = EmployerEntity(context: context)
                created.id = employer.id
                created.createdAt = Date()
                return created
            }()
            entity.name = employer.name
            entity.colour = employer.colour.rawValue
            entity.payCycle = employer.payCycle.rawValue
            entity.payCycleAnchor = employer.payCycleStartsOn
            entity.isArchived = employer.isArchived
            try context.save()
        }
    }
}

extension EmployerEntity {
    static func find(_ id: UUID, in context: NSManagedObjectContext) throws -> EmployerEntity? {
        let request = EmployerEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetchFresh(request).first
    }

    func employer() throws -> Employer {
        guard let id, let name, let payCycleAnchor,
              let colour = colour.flatMap(EmployerColour.init(rawValue:)),
              let payCycle = payCycle.flatMap(PayCycle.init(rawValue:))
        else { throw ShiftStoreError.unreadableRecord(entity: "EmployerEntity") }
        return Employer(id: id, name: name, colour: colour, payCycle: payCycle, payCycleStartsOn: payCycleAnchor, isArchived: isArchived)
    }
}
