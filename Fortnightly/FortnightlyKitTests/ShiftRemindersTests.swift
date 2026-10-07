import Foundation
import Testing
@testable import FortnightlyKit

@Suite("Shift reminders")
struct ShiftRemindersTests {
    @Test("Rebuilding reminders keeps the open shift's clock-out prompts")
    func rebuildKeepsOpenShiftsClockOutPrompts() throws {
        let shifts = InMemoryShiftRepository()
        let tonight = shifts.recordOnShift(rosteredFrom: october(19, at: 17), to: october(19, at: 22, 30), clockedInAt: october(19, at: 17), at: .cafeRoma)
        let thursday = shifts.recordRosteredShift(from: october(22, at: 17), to: october(22, at: 23), at: .thaiExpress)
        let reminders = SpyReminderScheduler()

        try RefreshShiftReminders(
            shifts: shifts,
            employers: InMemoryEmployerRepository(.cafeRoma, .thaiExpress),
            reminders: reminders,
            now: { october(19, at: 19) }
        ).execute()

        let tonightsPrompts = reminders.reminderWindow.filter { $0.shiftID == tonight.id }
        #expect(tonightsPrompts.map(\.moment) == [.clockOutDue, .clockOutOverdue])
        #expect(tonightsPrompts.map(\.firesAt) == [october(19, at: 22, 30), october(19, at: 23, 15)])
        let thursdaysPrompts = reminders.reminderWindow.filter { $0.shiftID == thursday.id }
        #expect(thursdaysPrompts.map(\.moment) == [.clockInDue, .clockInOverdue, .clockOutDue, .clockOutOverdue])
    }
}
