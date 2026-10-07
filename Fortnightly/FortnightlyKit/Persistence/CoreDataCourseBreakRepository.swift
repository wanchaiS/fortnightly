import CoreData
import Foundation

public struct CoreDataCourseBreakRepository: CourseBreakRepository, @unchecked Sendable {
    private let context: NSManagedObjectContext

    public init(store: ShiftStore) {
        context = store.makeContext()
    }

    public func courseBreaks(overlapping interval: DateInterval) throws -> [CourseBreak] {
        // `endsOn` is the start of the last day, which runs a day past it. A day's margin is enough;
        // the use cases work out the exact days.
        let dayBeforeStart = interval.start.addingTimeInterval(-24 * 3600)
        return try fetch(NSPredicate(format: "startsOn < %@ AND endsOn >= %@", interval.end as NSDate, dayBeforeStart as NSDate))
    }

    public func allCourseBreaks() throws -> [CourseBreak] {
        try fetch(nil)
    }

    public func save(_ courseBreak: CourseBreak) throws {
        try context.performAndWait {
            let entity = try CourseBreakEntity.find(courseBreak.id, in: context) ?? {
                let created = CourseBreakEntity(context: context)
                created.id = courseBreak.id
                return created
            }()
            entity.name = courseBreak.name
            entity.startsOn = courseBreak.startsOn
            entity.endsOn = courseBreak.endsOn
            try context.save()
        }
    }

    public func remove(_ id: CourseBreak.ID) throws {
        try context.performAndWait {
            guard let entity = try CourseBreakEntity.find(id, in: context) else { return }
            context.delete(entity)
            try context.save()
        }
    }

    private func fetch(_ predicate: NSPredicate?) throws -> [CourseBreak] {
        try context.performAndWait {
            let request = CourseBreakEntity.fetchRequest()
            request.predicate = predicate
            request.sortDescriptors = [NSSortDescriptor(key: "startsOn", ascending: true)]
            return try context.fetch(request).map { try $0.courseBreak() }
        }
    }
}

extension CourseBreakEntity {
    static func find(_ id: UUID, in context: NSManagedObjectContext) throws -> CourseBreakEntity? {
        let request = CourseBreakEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func courseBreak() throws -> CourseBreak {
        guard let id, let name, let startsOn, let endsOn else { throw ShiftStoreError.unreadableRecord(entity: "CourseBreakEntity") }
        return CourseBreak(id: id, name: name, startsOn: startsOn, endsOn: endsOn)
    }
}
