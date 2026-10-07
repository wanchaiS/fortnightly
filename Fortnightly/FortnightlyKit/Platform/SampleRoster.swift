import Foundation

extension FortnightlyServices {
    /// Two jobs and a fortnight of shifts around today, for markers and screenshots. Written straight to the
    /// store because the rules rightly refuse to roster shifts that have already happened.
    /// Does nothing once any employer exists, so a real record is never mixed with sample data.
    public func loadSampleRoster() throws {
        guard try employers.employers(includingArchived: true).isEmpty else { return }
        let cafeRoma = Employer(name: "Café Roma", colour: .violet, payCycleStartsOn: currentTime)
        let thaiExpress = Employer(name: "Thai Express", colour: .teal, payCycle: .weekly, payCycleStartsOn: currentTime)
        try employers.save(cafeRoma)
        try employers.save(thaiExpress)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: currentTime)
        func time(daysFromToday days: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            calendar.date(byAdding: DateComponents(day: days, hour: hour, minute: minute), to: today)!
        }
        func worked(_ employer: Employer, _ start: Date, _ finish: Date) throws {
            try shifts.save(Shift(employerID: employer.id, rosteredStart: start, rosteredFinish: finish, clockedInAt: start, clockedOutAt: finish, status: .worked))
        }
        func rostered(_ employer: Employer, _ start: Date, _ finish: Date) throws {
            try shifts.save(Shift(employerID: employer.id, rosteredStart: start, rosteredFinish: finish))
        }

        try worked(cafeRoma, time(daysFromToday: -7, 7), time(daysFromToday: -7, 13))
        try worked(thaiExpress, time(daysFromToday: -6, 17), time(daysFromToday: -6, 22, 30))
        try worked(cafeRoma, time(daysFromToday: -5, 7), time(daysFromToday: -5, 13))
        try worked(cafeRoma, time(daysFromToday: -2, 9), time(daysFromToday: -2, 15, 15))
        try worked(thaiExpress, time(daysFromToday: -2, 17), time(daysFromToday: -2, 23))
        // Yesterday's shift finished without a clock-in.
        try rostered(thaiExpress, time(daysFromToday: -1, 17), time(daysFromToday: -1, 22))
        // Tonight's shift started five minutes ago: clock-in due.
        let startedFiveMinutesAgo = calendar.date(byAdding: .minute, value: -5, to: currentTime)!
        try rostered(cafeRoma, startedFiveMinutesAgo, startedFiveMinutesAgo.addingTimeInterval(5.5 * 3600))
        try rostered(thaiExpress, time(daysFromToday: 3, 17), time(daysFromToday: 3, 23))

        try refreshShiftReminders.execute()
        display.shiftsDidChange()
    }
}
