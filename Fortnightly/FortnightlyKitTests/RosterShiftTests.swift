import Foundation
import Testing
@testable import FortnightlyKit

@Suite("Rostering a shift")
struct RosterShiftTests {
    private let shifts = InMemoryShiftRepository()
    private let employers = InMemoryEmployerRepository(.cafeRoma, .thaiExpress)
    private let reminders = SpyReminderScheduler()

    @discardableResult
    private func rosterShift(
        at employer: Employer,
        from start: Date,
        to finish: Date,
        now: Date = october(12, at: 9),
        acknowledgingWorkLimitBreach: Bool = false
    ) throws(RosterShiftError) -> Shift {
        try RosterShift(
            shifts: shifts,
            employers: employers,
            courseBreaks: InMemoryCourseBreakRepository(),
            reminders: reminders,
            display: IgnoredDisplayRefresh(),
            calendar: Sydney.calendar,
            now: { now }
        ).execute(ShiftRosterRequest(
            employerID: employer.id,
            start: start,
            finish: finish,
            acknowledgingWorkLimitBreach: acknowledgingWorkLimitBreach
        ))
    }

    @Test("Rostering a valid shift saves it and schedules its clock-in and clock-out reminders")
    func validShiftIsRostered() throws {
        let shift = try rosterShift(at: .cafeRoma, from: october(17, at: 17), to: october(17, at: 22, 30))

        #expect(shifts.savedShifts == [Shift(
            id: shift.id,
            employerID: Employer.cafeRoma.id,
            rosteredStart: october(17, at: 17),
            rosteredFinish: october(17, at: 22, 30),
            status: .rostered
        )])
        #expect(reminders.scheduledShiftIDs == [shift.id])
    }

    @Test("Rostering a shift that overlaps another employer's shift is rejected")
    func overlappingShiftIsRejected() {
        shifts.recordRosteredShift(from: october(17, at: 17), to: october(17, at: 22, 30), at: .cafeRoma)

        #expect(throws: RosterShiftError.overlaps(
            employerName: "Café Roma",
            existingShift: DateInterval(start: october(17, at: 17), end: october(17, at: 22, 30))
        )) {
            try rosterShift(at: .thaiExpress, from: october(17, at: 22), to: october(17, at: 23, 30))
        }
        #expect(shifts.savedShifts.count == 1)
    }

    @Test("A shift starting exactly when another finishes is not an overlap")
    func backToBackShiftsAreAllowed() throws {
        shifts.recordRosteredShift(from: october(17, at: 12), to: october(17, at: 17), at: .cafeRoma)

        try rosterShift(at: .thaiExpress, from: october(17, at: 17), to: october(17, at: 22))

        #expect(shifts.savedShifts.count == 2)
    }

    @Test("Rostering a shift that takes a fortnight past 48 hours needs the student's acknowledgement")
    func workLimitBreachNeedsAcknowledgement() throws {
        let now = october(19, at: 9)
        shifts.recordSixHourShifts(days: 7, startingOctober: 12) // worked Mon 12 – Sun 18: 42 hrs
        shifts.recordRosteredShift(from: october(19, at: 10), to: october(19, at: 13)) // rostered: 45 hrs
        let fortnightFromOctober12 = WorkFortnight.starting(inWeekOf: october(12), calendar: Sydney.calendar)

        #expect(throws: RosterShiftError.wouldBreachWorkLimit(fortnight: fortnightFromOctober12, projectedHours: 51)) {
            try rosterShift(at: .thaiExpress, from: october(24, at: 17), to: october(24, at: 23), now: now)
        }
        #expect(shifts.savedShifts.count == 8)

        try rosterShift(at: .thaiExpress, from: october(24, at: 17), to: october(24, at: 23), now: now, acknowledgingWorkLimitBreach: true)

        #expect(shifts.savedShifts.count == 9)
    }
}
