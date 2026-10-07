import Foundation
import Testing
@testable import FortnightlyKit

@Suite("Logging a past shift")
struct LogPastShiftTests {
    /// Mon 19 Oct, 5:05pm.
    private static let now = october(19, at: 17, 5)
    private let shifts = InMemoryShiftRepository()
    private let employers = InMemoryEmployerRepository(.cafeRoma, .thaiExpress)

    init() {
        shifts.recordStoryboardShifts()
        shifts.recordRosteredShift(from: october(19, at: 17), to: october(19, at: 22, 30), at: .cafeRoma)
    }

    private var logging: LogPastShift {
        LogPastShift(
            shifts: shifts,
            employers: employers,
            courseBreaks: InMemoryCourseBreakRepository(),
            reminders: SpyReminderScheduler(),
            display: IgnoredDisplayRefresh(),
            calendar: Sydney.calendar,
            now: { Self.now }
        )
    }

    @Test("Entering a missed shift's real times records it as worked, and it's no longer missed")
    func missedShiftsRealTimesAreRecorded() throws {
        let sunday = try #require(try shifts.rosteredShifts().first { $0.rosteredStart == october(18, at: 17) })

        try logging.execute(PastShiftRequest(subject: .missedShift(sunday.id), start: october(18, at: 17, 10), finish: october(18, at: 22, 20)))

        let recorded = try #require(try shifts.shift(withID: sunday.id))
        #expect(recorded.status == .worked)
        #expect(recorded.clockedInAt == october(18, at: 17, 10))
        #expect(recorded.clockedOutAt == october(18, at: 22, 20))
        #expect(try ReviewMissedShifts(shifts: shifts, employers: employers, now: { Self.now }).execute().isEmpty)
    }

    @Test("A past shift that overlaps another shift is rejected")
    func overlappingPastShiftIsRejected() {
        let rosterBefore = shifts.savedShifts

        #expect(throws: LogPastShiftError.overlaps(
            employerName: "Café Roma",
            existingShift: DateInterval(start: october(17, at: 9), end: october(17, at: 15, 15))
        )) {
            try logging.execute(PastShiftRequest(
                subject: .newShift(employerID: Employer.thaiExpress.id),
                start: october(17, at: 14),
                finish: october(17, at: 16)
            ))
        }
        #expect(shifts.savedShifts == rosterBefore)
    }
}
