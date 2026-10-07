import Foundation
import Testing
@testable import FortnightlyKit

@Suite("Clocking out")
struct ClockOutOfShiftTests {
    private let shifts = InMemoryShiftRepository()

    @discardableResult
    private func clockOut(of shift: Shift, finishedAt time: ClockOutTime, now: Date) throws(ClockOutOfShiftError) -> ClockOutOutcome {
        try ClockOutOfShift(
            shifts: shifts,
            courseBreaks: InMemoryCourseBreakRepository(),
            reminders: SpyReminderScheduler(),
            display: IgnoredDisplayRefresh(),
            calendar: Sydney.calendar,
            now: { now }
        ).execute(shiftID: shift.id, finishedAt: time)
    }

    @Test("Clocking out records the hours even when they take the fortnight over the limit, and flags the breach")
    func breachIsRecordedAndFlagged() throws {
        shifts.recordSixHourShifts(days: 7, startingOctober: 5) // Mon 5 – Sun 11: 42 hrs
        shifts.recordWorkedShift(from: october(12, at: 10), to: october(12, at: 13)) // 45 hrs in the fortnight from Mon 5
        let shift = shifts.recordOnShift(rosteredFrom: october(17, at: 17), to: october(17, at: 22, 30), clockedInAt: october(17, at: 17))

        let outcome = try clockOut(of: shift, finishedAt: .now, now: october(17, at: 22, 30))

        let worked = try #require(try shifts.shift(withID: shift.id))
        #expect(worked.status == .worked)
        #expect(worked.clockedOutAt == october(17, at: 22, 30))
        #expect(outcome.fortnightsOverLimit.map(\.hoursTowardLimit) == [50.5])
    }

    @Test("Clocking out of a shift left open for 19 hours asks for the real finish time")
    func forgottenClockOutIsQueried() throws {
        let shift = shifts.recordOnShift(rosteredFrom: october(17, at: 17), to: october(17, at: 22, 30), clockedInAt: october(17, at: 17))

        #expect(throws: ClockOutOfShiftError.unusuallyLong(hours: 19)) {
            try clockOut(of: shift, finishedAt: .now, now: october(18, at: 12))
        }
        #expect(try shifts.shift(withID: shift.id)?.status == .onShift)
    }
}
