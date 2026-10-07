import Foundation
@testable import FortnightlyKit

enum Sydney {
    /// Sydney time, with weeks starting on Sunday like a US-region phone.
    /// The Sunday-midnight test therefore also proves the app forces work fortnights to start on Monday.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        calendar.firstWeekday = 1
        return calendar
    }()
}

/// A Sydney local time in October 2026 (Mon 5, Mon 12, Mon 19 and Mon 26 start weeks).
func october(_ day: Int, at hour: Int = 0, _ minute: Int = 0) -> Date {
    Sydney.calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
}

enum CafeRoma {
    static let id = UUID()
}

extension InMemoryShiftRepository {
    /// A shift clocked in and out exactly as rostered.
    func recordWorkedShift(from start: Date, to finish: Date, employerID: Employer.ID = CafeRoma.id) {
        try! save(Shift(
            employerID: employerID,
            rosteredStart: start,
            rosteredFinish: finish,
            clockedInAt: start,
            clockedOutAt: finish,
            status: .worked
        ))
    }

    /// One worked 10am–4pm shift on each of `days` consecutive days.
    func recordSixHourShifts(days: Int, startingOctober firstDay: Int) {
        for day in firstDay ..< firstDay + days {
            recordWorkedShift(from: october(day, at: 10), to: october(day, at: 16))
        }
    }
}
