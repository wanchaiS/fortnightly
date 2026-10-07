import Foundation
import Testing
@testable import FortnightlyKit

@Suite("Reviewing fortnight hours")
struct ReviewFortnightHoursTests {
    private let shifts = InMemoryShiftRepository()
    private let courseBreaks = InMemoryCourseBreakRepository()

    private func reviewHours(on date: Date, now: Date = october(26)) throws -> FortnightHoursReview {
        try ReviewFortnightHours(shifts: shifts, courseBreaks: courseBreaks, calendar: Sydney.calendar, now: { now })
            .execute(on: date)
    }

    @Test("Hours in weeks 2 and 3 breach the limit even when weeks 1 and 2 are within it")
    func breachInOverlappingFortnight() throws {
        // Modelled on the Home Affairs example: every week belongs to two work fortnights.
        shifts.recordSixHourShifts(days: 3, startingOctober: 5) // week 1: 18 hrs
        shifts.recordSixHourShifts(days: 5, startingOctober: 12) // week 2: 30 hrs
        shifts.recordSixHourShifts(days: 5, startingOctober: 19) // week 3: 30 hrs

        let review = try reviewHours(on: october(14))

        #expect(review.fortnightStartedLastWeek.hoursTowardLimit == 48)
        #expect(review.fortnightStartedLastWeek.status != .overLimit)
        #expect(review.fortnightStartingThisWeek.hoursTowardLimit == 60)
        #expect(review.fortnightStartingThisWeek.status == .overLimit)
    }

    @Test("A fortnight at exactly 48 hours is within the limit, and 48.5 is over")
    func limitBoundary() throws {
        shifts.recordSixHourShifts(days: 8, startingOctober: 5) // 48 hrs
        #expect(try reviewHours(on: october(5)).fortnightStartingThisWeek.status != .overLimit)

        shifts.recordWorkedShift(from: october(16, at: 18), to: october(16, at: 18, 30))
        #expect(try reviewHours(on: october(5)).fortnightStartingThisWeek.status == .overLimit)
    }

    @Test("A shift crossing Sunday midnight counts in the week each hour was worked")
    func shiftAcrossSundayMidnight() throws {
        shifts.recordWorkedShift(from: october(18, at: 22), to: october(19, at: 2))

        let review = try reviewHours(on: october(19))

        #expect(review.fortnightStartedLastWeek.hoursTowardLimit == 4)
        #expect(review.fortnightStartingThisWeek.hoursTowardLimit == 2)
    }

    @Test("Hours worked during a course break don't count toward the limit")
    func courseBreakHoursExcluded() throws {
        courseBreaks.add(CourseBreak(name: "Mid-semester break", startsOn: october(19), endsOn: october(25)))
        shifts.recordSixHourShifts(days: 5, startingOctober: 12) // in session: 30 hrs
        shifts.recordSixHourShifts(days: 5, startingOctober: 19) // during the break: 30 hrs

        let fortnight = try reviewHours(on: october(19)).fortnightStartedLastWeek

        #expect(fortnight.hoursTowardLimit == 30)
        #expect(fortnight.status != .overLimit)
    }

    @Test("An open shift's hours split at \"now\" into worked and still rostered")
    func openShiftSplitsAtNow() throws {
        shifts.recordStoryboardShifts()
        shifts.recordOnShift(rosteredFrom: october(19, at: 17), to: october(19, at: 22, 30), clockedInAt: october(19, at: 17))

        let fortnight = try reviewHours(on: october(19), now: october(19, at: 19)).fortnightStartedLastWeek

        #expect(fortnight.hoursWorked == 31.75) // 29.75 finished + 2 so far tonight
        #expect(fortnight.hoursRostered == 14.5) // 5 missed Sunday + 6 Thursday + 3.5 still to come tonight
        #expect(fortnight.hoursTowardLimit == 46.25)
    }
}
