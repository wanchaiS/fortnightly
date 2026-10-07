import Foundation
import Testing
@testable import FortnightlyKit

@Suite("What to do now")
struct CurrentShiftTests {
    private let shifts = InMemoryShiftRepository()
    private let employers = InMemoryEmployerRepository(.cafeRoma)

    private func currentShift(at time: Date) throws -> CurrentShift {
        try ReviewCurrentShift(shifts: shifts, employers: employers, now: { time }).execute()
    }

    @Test("A started shift is clock-in due until its rostered finish, then it's missed")
    func clockInDueUntilRosteredFinishThenMissed() throws {
        let tonight = shifts.recordRosteredShift(from: october(19, at: 17), to: october(19, at: 22, 30))
        let listing = ShiftListing(shift: tonight, employer: .cafeRoma)

        #expect(try currentShift(at: october(19, at: 22, 29)) == .clockInDue(listing))
        #expect(try currentShift(at: october(19, at: 22, 30)) == .missed(listing))
        let missed = try ReviewMissedShifts(shifts: shifts, employers: employers, now: { october(19, at: 22, 30) }).execute()
        #expect(missed.map(\.shift) == [tonight])
    }

    @Test("Still clocked in after the rostered finish is clock-out due")
    func clockOutDueAfterRosteredFinish() throws {
        let tonight = shifts.recordOnShift(rosteredFrom: october(19, at: 17), to: october(19, at: 22, 30), clockedInAt: october(19, at: 17))
        let listing = ShiftListing(shift: tonight, employer: .cafeRoma)

        #expect(try currentShift(at: october(19, at: 22, 29)) == .onShift(listing))
        #expect(try currentShift(at: october(19, at: 22, 30)) == .clockOutDue(listing))
    }
}
