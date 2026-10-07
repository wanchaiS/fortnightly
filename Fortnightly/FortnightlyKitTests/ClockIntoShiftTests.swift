import Foundation
import Testing
@testable import FortnightlyKit

@Suite("Clocking in")
struct ClockIntoShiftTests {
    private let shifts = InMemoryShiftRepository()

    private func clockIn(to shift: Shift, startedAt time: ClockInTime, now: Date) throws(ClockIntoShiftError) {
        try ClockIntoShift(
            shifts: shifts,
            employers: InMemoryEmployerRepository(.cafeRoma, .thaiExpress),
            reminders: SpyReminderScheduler(),
            display: IgnoredDisplayRefresh(),
            now: { now }
        ).execute(shiftID: shift.id, startedAt: time)
    }

    @Test("Clocking in \"on time\" records the rostered start, not the time of the tap")
    func onTimeUsesRosteredStart() throws {
        let shift = shifts.recordRosteredShift(from: october(17, at: 17), to: october(17, at: 22, 30))

        try clockIn(to: shift, startedAt: .asRostered, now: october(17, at: 17, 20))

        let clockedIn = try #require(try shifts.shift(withID: shift.id))
        #expect(clockedIn.status == .onShift)
        #expect(clockedIn.clockedInAt == october(17, at: 17))
    }

    @Test("Clocking in while still on another shift is rejected")
    func anotherShiftStillOpen() throws {
        shifts.recordOnShift(rosteredFrom: october(17, at: 9), to: october(17, at: 15), clockedInAt: october(17, at: 9, 2), at: .cafeRoma)
        let thaiExpress = shifts.recordRosteredShift(from: october(17, at: 17), to: october(17, at: 22), at: .thaiExpress)

        #expect(throws: ClockIntoShiftError.anotherShiftInProgress(employerName: "Café Roma", since: october(17, at: 9, 2))) {
            try clockIn(to: thaiExpress, startedAt: .now, now: october(17, at: 17))
        }
        #expect(try shifts.shift(withID: thaiExpress.id)?.status == .rostered)
    }
}
