import Foundation
import Testing
@testable import FortnightlyKit

@Suite("What the board reads")
struct BoardReadingTests {
    private let shifts = InMemoryShiftRepository()

    init() {
        shifts.recordStoryboardShifts()
    }

    private func daysOfFortnightFromMonday12() throws -> [WorkDay] {
        try ReviewFortnightDays(
            shifts: shifts,
            employers: InMemoryEmployerRepository(.cafeRoma, .thaiExpress),
            courseBreaks: InMemoryCourseBreakRepository(),
            calendar: Sydney.calendar,
            now: { october(19, at: 17, 5) }
        ).execute(for: WorkFortnight.starting(inWeekOf: october(12), calendar: Sydney.calendar))
    }

    @Test("Each employer's hours in a fortnight are split into worked and still rostered")
    func employerHoursSplitIntoWorkedAndRostered() throws {
        shifts.recordOnShift(rosteredFrom: october(19, at: 17), to: october(19, at: 22, 30), clockedInAt: october(19, at: 17), at: .cafeRoma)

        let fortnight = try ReviewFortnightHours(
            shifts: shifts,
            courseBreaks: InMemoryCourseBreakRepository(),
            calendar: Sydney.calendar,
            now: { october(19, at: 19) }
        ).execute(on: october(19)).fortnightStartedLastWeek

        let cafeRoma = try #require(fortnight.hoursByEmployer.first { $0.employerID == Employer.cafeRoma.id })
        let thaiExpress = try #require(fortnight.hoursByEmployer.first { $0.employerID == Employer.thaiExpress.id })
        #expect(cafeRoma.hoursWorked == 20.25)
        #expect(cafeRoma.hoursRostered == 3.5)
        #expect(thaiExpress.hoursWorked == 11.5)
        #expect(thaiExpress.hoursRostered == 11)
    }

    @Test("Two jobs on one day are both listed, and the day's total adds them")
    func twoJobsOnOneDayAreBothListed() throws {
        let saturday = try #require(try daysOfFortnightFromMonday12().first { $0.date == october(17) })

        #expect(saturday.shifts.map(\.employerName) == ["Café Roma", "Thai Express"])
        #expect(saturday.hours == 12.25)
    }

    @Test("A not-working shift stays on its day but adds no hours")
    func notWorkingShiftStaysOnItsDay() throws {
        let missedSunday = try #require(shifts.savedShifts.first { $0.rosteredStart == october(18, at: 17) })
        try MarkShiftNotWorked(shifts: shifts, reminders: SpyReminderScheduler(), display: IgnoredDisplayRefresh())
            .execute(shiftID: missedSunday.id)

        let sunday = try #require(try daysOfFortnightFromMonday12().first { $0.date == october(18) })
        #expect(sunday.shifts.map(\.shift.status) == [.notWorked])
        #expect(sunday.hours == 0)
    }
}
