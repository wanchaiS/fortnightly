import Foundation
import Testing
@testable import FortnightlyKit

@Suite("Archiving an employer")
struct ArchiveEmployerTests {
    @Test("Archiving an employer keeps their worked hours counting")
    func archivingKeepsWorkedHoursCounting() throws {
        let now = october(19, at: 9)
        let shifts = InMemoryShiftRepository()
        let employers = InMemoryEmployerRepository(.cafeRoma, .thaiExpress)
        shifts.recordSixHourShifts(days: 3, startingOctober: 12) // Café Roma: 18 hrs
        shifts.recordWorkedShift(from: october(13, at: 17), to: october(13, at: 22, 30), at: .thaiExpress) // 5.5 hrs
        shifts.recordWorkedShift(from: october(17, at: 17), to: october(17, at: 23), at: .thaiExpress) // 6 hrs

        try ArchiveEmployer(employers: employers, shifts: shifts, display: IgnoredDisplayRefresh(), now: { now })
            .execute(employerID: Employer.thaiExpress.id)

        #expect(try employers.employers(includingArchived: false).map(\.name) == ["Café Roma"])
        let fortnight = try ReviewFortnightHours(
            shifts: shifts,
            courseBreaks: InMemoryCourseBreakRepository(),
            calendar: Sydney.calendar,
            now: { now }
        ).execute(on: october(19)).fortnightStartedLastWeek
        #expect(fortnight.hoursTowardLimit == 29.5)
    }
}
