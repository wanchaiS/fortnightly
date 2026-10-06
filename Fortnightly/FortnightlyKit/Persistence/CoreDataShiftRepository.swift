import CoreData
import Foundation

public struct CoreDataShiftRepository: ShiftRepository, @unchecked Sendable {
    private let context: NSManagedObjectContext

    public init(store: ShiftStore) {
        context = store.makeContext()
    }

    public func shift(withID id: Shift.ID) throws -> Shift? {
        try context.performAndWait {
            try ShiftEntity.find(id, in: context)?.shift()
        }
    }

    public func upcomingShifts(after date: Date) throws -> [Shift] {
        try context.performAndWait {
            let request = ShiftEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "status == %@ AND rosteredFinish > %@",
                ShiftStatus.rostered.rawValue, date as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(key: "rosteredStart", ascending: true)]
            return try context.fetch(request).map { try $0.shift() }
        }
    }

    public func save(_ shift: Shift) throws {
        try context.performAndWait {
            guard let employer = try EmployerEntity.find(shift.employerID, in: context) else {
                throw ShiftStoreError.employerMissing(shift.employerID)
            }
            let entity = try ShiftEntity.find(shift.id, in: context) ?? {
                let created = ShiftEntity(context: context)
                created.id = shift.id
                return created
            }()
            entity.employer = employer
            entity.rosteredStart = shift.rosteredStart
            entity.rosteredFinish = shift.rosteredFinish
            entity.clockedInAt = shift.clockedInAt
            entity.clockedOutAt = shift.clockedOutAt
            entity.status = shift.status.rawValue
            entity.note = shift.note
            try context.save()
        }
    }
}

extension ShiftEntity {
    static func find(_ id: UUID, in context: NSManagedObjectContext) throws -> ShiftEntity? {
        let request = ShiftEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func shift() throws -> Shift {
        guard let id, let employerID = employer?.id, let rosteredStart, let rosteredFinish,
              let status = status.flatMap(ShiftStatus.init(rawValue:))
        else { throw ShiftStoreError.unreadableRecord(entity: "ShiftEntity") }
        return Shift(
            id: id,
            employerID: employerID,
            rosteredStart: rosteredStart,
            rosteredFinish: rosteredFinish,
            clockedInAt: clockedInAt,
            clockedOutAt: clockedOutAt,
            status: status,
            note: note
        )
    }
}
