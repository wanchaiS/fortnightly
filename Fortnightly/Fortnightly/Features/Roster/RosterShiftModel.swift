import FortnightlyKit
import Foundation
import Observation

@Observable
final class RosterShiftModel {
    var employerID: Employer.ID?
    var day: Date
    var startTime: Date
    var finishTime: Date

    private(set) var employers: [Employer] = []
    /// The shift's effect on each fortnight it falls in, before it's saved.
    private(set) var effects: [FortnightEffect] = []
    /// Other shifts already on the chosen day, for the preview row.
    private(set) var otherShiftsThatDay: [ShiftListing] = []
    /// A rule the shift breaks (an overlap, an AM/PM mistake), shown under the form as it's typed.
    private(set) var ruleProblem: ProblemMessage?
    var saveProblem: ProblemMessage?

    let editing: ShiftListing?
    private let services: FortnightlyServices

    init(services: FortnightlyServices, day: Date?, editing: ShiftListing?) {
        self.services = services
        self.editing = editing
        let calendar = Calendar.current
        if let shift = editing?.shift {
            employerID = shift.employerID
            self.day = calendar.startOfDay(for: shift.rosteredStart)
            startTime = shift.rosteredStart
            finishTime = shift.rosteredFinish
        } else {
            var chosenDay = calendar.startOfDay(for: day ?? .now)
            // With no day chosen, suggest tomorrow once today's usual evening start has passed.
            if day == nil, calendar.date(bySettingHour: 17, minute: 0, second: 0, of: chosenDay)! <= .now {
                chosenDay = calendar.date(byAdding: .day, value: 1, to: chosenDay)!
            }
            self.day = chosenDay
            startTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: chosenDay)!
            finishTime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: chosenDay)!
        }
    }

    var breach: FortnightEffect? { effects.first { $0.after.status == .overLimit } }
    var canSave: Bool { request != nil && ruleProblem == nil }

    var start: Date { shiftTimes(on: day, from: startTime, to: finishTime).start }
    var finish: Date { shiftTimes(on: day, from: startTime, to: finishTime).end }

    /// The day's other shifts, then this one drawn dashed.
    var previewSegments: [DayBarSegment] {
        let others = otherShiftsThatDay.map { DayBarSegment(listing: $0, now: .now) }
        guard let employer = employers.first(where: { $0.id == employerID }) else { return others }
        return others + [DayBarSegment(colour: employer.colour, hours: finish.timeIntervalSince(start) / 3600, form: .adding)]
    }

    func load() {
        do {
            employers = try services.reviewJobs.execute().employers
            if employerID == nil { employerID = employers.first?.id }
        } catch {
            ruleProblem = ProblemMessage(error)
        }
        updatePreview()
    }

    func updatePreview() {
        loadOtherShiftsThatDay()
        guard let request else { effects = []; return }
        do {
            effects = try services.rosterShift.preview(request)
            ruleProblem = nil
        } catch {
            effects = []
            ruleProblem = ProblemMessage(error)
        }
    }

    /// Seeing the breach and choosing "Add anyway" is the student's acknowledgement.
    func save() -> Bool {
        guard var request else { return false }
        request.acknowledgingWorkLimitBreach = breach != nil
        do {
            try services.rosterShift.execute(request)
            return true
        } catch {
            saveProblem = ProblemMessage(error)
            return false
        }
    }

    private var request: ShiftRosterRequest? {
        guard let employerID else { return nil }
        return ShiftRosterRequest(employerID: employerID, start: start, finish: finish, editing: editing?.id)
    }

    private func loadOtherShiftsThatDay() {
        let fortnight = WorkFortnight.starting(inWeekOf: day, calendar: .current)
        let days = (try? services.reviewFortnightDays.execute(for: fortnight)) ?? []
        otherShiftsThatDay = days.first { Calendar.current.isDate($0.date, inSameDayAs: day) }?
            .shifts.filter { $0.id != editing?.id && $0.shift.status != .notWorked } ?? []
    }
}
