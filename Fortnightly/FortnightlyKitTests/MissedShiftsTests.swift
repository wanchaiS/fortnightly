import Foundation
import Testing
@testable import FortnightlyKit

@Suite("Missed shifts")
struct MissedShiftsTests {
    /// Mon 19 Oct, 5:05pm: tonight's Café Roma shift has started but not finished.
    private static let now = october(19, at: 17, 5)
    private let shifts = InMemoryShiftRepository()
    private let employers = InMemoryEmployerRepository(.cafeRoma, .thaiExpress)

    init() {
        shifts.recordStoryboardShifts()
        shifts.recordRosteredShift(from: october(19, at: 17), to: october(19, at: 22, 30), at: .cafeRoma)
    }

    private func missedShifts() throws -> [ShiftListing] {
        try ReviewMissedShifts(shifts: shifts, employers: employers, now: { Self.now }).execute()
    }

    @Test("A shift that finished without a clock-in is listed as missed; one still running isn't")
    func finishedWithoutClockInIsMissed() throws {
        let missed = try missedShifts()

        #expect(missed.map(\.shift.rosteredStart) == [october(18, at: 17)])
        #expect(missed.map(\.employerName) == ["Thai Express"])
    }

    @Test("Marking a missed shift as not worked removes its hours")
    func notWorkedRemovesItsHours() throws {
        let sunday = try #require(try missedShifts().first)

        try MarkShiftNotWorked(shifts: shifts, reminders: SpyReminderScheduler(), display: IgnoredDisplayRefresh())
            .execute(shiftID: sunday.shift.id)

        let fortnight = try ReviewFortnightHours(
            shifts: shifts,
            courseBreaks: InMemoryCourseBreakRepository(),
            calendar: Sydney.calendar,
            now: { Self.now }
        ).execute(on: october(19)).fortnightStartedLastWeek
        #expect(fortnight.hoursTowardLimit == 41.25)
        #expect(try missedShifts().isEmpty)
    }
}
