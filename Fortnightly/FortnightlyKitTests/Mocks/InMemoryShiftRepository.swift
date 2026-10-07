import Foundation
@testable import FortnightlyKit

/// Plain in-memory storage standing in for Core Data.
/// The interval queries deliberately return every stored shift, so tests prove the
/// use cases themselves pick the hours and days inside a fortnight.
final class InMemoryShiftRepository: ShiftRepository, @unchecked Sendable {
    private(set) var savedShifts: [Shift] = []

    func shift(withID id: Shift.ID) throws -> Shift? {
        savedShifts.first { $0.id == id }
    }

    func openShift() throws -> Shift? {
        savedShifts.first { $0.status == .onShift }
    }

    func upcomingShifts(after date: Date) throws -> [Shift] {
        savedShifts
            .filter { $0.status == .rostered && $0.rosteredFinish > date }
            .sorted { $0.rosteredStart < $1.rosteredStart }
    }

    func rosteredShifts() throws -> [Shift] {
        savedShifts
            .filter { $0.status == .rostered }
            .sorted { $0.rosteredStart < $1.rosteredStart }
    }

    func shiftsCountingTowardWorkLimit(overlapping interval: DateInterval) throws -> [Shift] {
        savedShifts
    }

    func shifts(rosteredToStartIn interval: DateInterval) throws -> [Shift] {
        savedShifts
    }

    func save(_ shift: Shift) throws {
        if let index = savedShifts.firstIndex(where: { $0.id == shift.id }) {
            savedShifts[index] = shift
        } else {
            savedShifts.append(shift)
        }
    }
}
