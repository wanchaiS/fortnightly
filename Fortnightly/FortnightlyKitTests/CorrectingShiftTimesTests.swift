import Foundation
import Testing
@testable import FortnightlyKit

@Suite("Correcting a worked shift")
struct CorrectingShiftTimesTests {
    private let shifts = InMemoryShiftRepository()
    private let saturday = Shift(
        employerID: Employer.cafeRoma.id,
        rosteredStart: october(17, at: 9),
        rosteredFinish: october(17, at: 15),
        clockedInAt: october(17, at: 9),
        clockedOutAt: october(17, at: 15),
        status: .worked
    )

    init() throws {
        try shifts.save(saturday)
    }

    private func correctSaturday(from start: Date, to finish: Date) throws {
        try LogPastShift(
            shifts: shifts,
            employers: InMemoryEmployerRepository(.cafeRoma),
            courseBreaks: InMemoryCourseBreakRepository(),
            reminders: SpyReminderScheduler(),
            display: IgnoredDisplayRefresh(),
            calendar: Sydney.calendar,
            now: { october(19, at: 17, 5) }
        ).execute(PastShiftRequest(subject: .workedShift(saturday.id), start: start, finish: finish))
    }

    @Test("Correcting a worked shift's times keeps its rostered times")
    func correctionKeepsRosteredTimes() throws {
        try correctSaturday(from: october(17, at: 9), to: october(17, at: 15, 15))

        let corrected = try #require(try shifts.shift(withID: saturday.id))
        #expect(corrected.clockedOutAt == october(17, at: 15, 15))
        #expect(corrected.rosteredStart == october(17, at: 9))
        #expect(corrected.rosteredFinish == october(17, at: 15))
    }

    @Test("Correcting a worked shift's times doesn't count as overlapping itself")
    func correctionDoesNotClashWithItself() throws {
        try correctSaturday(from: october(17, at: 8, 45), to: october(17, at: 15, 15))

        #expect(shifts.savedShifts.count == 1)
        #expect(try shifts.shift(withID: saturday.id)?.clockedInAt == october(17, at: 8, 45))
    }
}
