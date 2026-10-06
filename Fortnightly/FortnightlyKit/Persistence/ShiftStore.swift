import CoreData
import Foundation

public enum ShiftStoreError: Error {
    case appGroupUnavailable
    case modelMissing
    case employerMissing(UUID)
    case unreadableRecord(entity: String)
}

/// The Core Data stack, stored in the App Group container so every process sees the same shifts.
public final class ShiftStore: @unchecked Sendable {
    /// One store per process. Opening it twice in the same process would load two coordinators on one file.
    public static let appGroup: Result<ShiftStore, Error> = Result {
        guard let directory = AppGroup.containerURL else { throw ShiftStoreError.appGroupUnavailable }
        return try ShiftStore(storeURL: directory.appending(path: "Fortnightly.sqlite"))
    }

    public let container: NSPersistentContainer

    /// Loaded once: several NSManagedObjectModel instances for the same entities confuse Core Data (notably in tests).
    private static let model: Result<NSManagedObjectModel, Error> = Result {
        guard let url = Bundle(for: ShiftStore.self).url(forResource: "Fortnightly", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url)
        else { throw ShiftStoreError.modelMissing }
        return model
    }

    public init(storeURL: URL) throws {
        container = NSPersistentContainer(name: "Fortnightly", managedObjectModel: try Self.model.get())
        let description = NSPersistentStoreDescription(url: storeURL)
        // Lets the app notice writes made by the widget and notification extension processes.
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// A private-queue context; repositories wrap every call in `performAndWait`, so they are safe from any thread.
    func makeContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
