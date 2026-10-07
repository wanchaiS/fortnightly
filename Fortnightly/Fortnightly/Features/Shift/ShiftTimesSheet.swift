import FortnightlyKit
import Observation
import SwiftUI

/// The real times of a finished shift: a past shift that was never rostered, a missed one, or a correction.
struct ShiftTimesSheet: View {
    enum Purpose: Identifiable {
        case logPastShift(day: Date)
        case enterMissedTimes(ShiftListing)
        case correct(ShiftListing)

        var id: String {
            switch self {
            case let .logPastShift(day): "log-\(day)"
            case let .enterMissedTimes(listing): "missed-\(listing.id)"
            case let .correct(listing): "correct-\(listing.id)"
            }
        }
    }

    @State private var model: ShiftTimesModel
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    init(purpose: Purpose, services: FortnightlyServices, onDone: @escaping () -> Void) {
        _model = State(initialValue: ShiftTimesModel(purpose: purpose, services: services))
        self.onDone = onDone
    }

    var body: some View {
        NavigationStack {
            Form {
                switch model.purpose {
                case .logPastShift:
                    Section("Employer") {
                        Picker("Employer", selection: $model.employerID) {
                            ForEach(model.employers) { employer in
                                Text(employer.name).tag(Optional(employer.id))
                            }
                        }
                        .labelsHidden()
                    }
                case let .enterMissedTimes(listing), let .correct(listing):
                    Section {
                        LabeledContent(listing.employerName, value: "Rostered \(listing.shift.rosteredTimesText)")
                    }
                }
                Section {
                    DatePicker("Day", selection: $model.day, displayedComponents: .date)
                    DatePicker("Started", selection: $model.startTime, displayedComponents: .hourAndMinute)
                    DatePicker("Finished", selection: $model.finishTime, displayedComponents: .hourAndMinute)
                } header: {
                    Text("Times you actually worked")
                } footer: {
                    Text("\(model.hours.hoursDescription) hours. A finish before the start means the shift ended after midnight.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.ground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if model.save() { onDone() }
                    }
                    .fontWeight(.semibold)
                    .disabled(model.employerID == nil)
                }
            }
        }
        .tint(Palette.tint)
        .onAppear(perform: model.load)
        .problemAlert($model.problem)
    }

    private var title: String {
        switch model.purpose {
        case .logPastShift: "Log a past shift"
        case .enterMissedTimes: "Enter my times"
        case .correct: "Correct times"
        }
    }
}

@Observable
final class ShiftTimesModel {
    var employerID: Employer.ID?
    var day: Date
    var startTime: Date
    var finishTime: Date
    private(set) var employers: [Employer] = []
    var problem: ProblemMessage?

    let purpose: ShiftTimesSheet.Purpose
    private let services: FortnightlyServices

    init(purpose: ShiftTimesSheet.Purpose, services: FortnightlyServices) {
        self.purpose = purpose
        self.services = services
        let calendar = Calendar.current
        switch purpose {
        case let .logPastShift(chosenDay):
            day = calendar.startOfDay(for: chosenDay)
            startTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: chosenDay)!
            finishTime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: chosenDay)!
        case let .enterMissedTimes(listing):
            employerID = listing.shift.employerID
            day = calendar.startOfDay(for: listing.shift.rosteredStart)
            startTime = listing.shift.rosteredStart
            finishTime = listing.shift.rosteredFinish
        case let .correct(listing):
            employerID = listing.shift.employerID
            day = calendar.startOfDay(for: listing.shift.clockedInAt ?? listing.shift.rosteredStart)
            startTime = listing.shift.clockedInAt ?? listing.shift.rosteredStart
            finishTime = listing.shift.clockedOutAt ?? listing.shift.rosteredFinish
        }
    }

    var start: Date { shiftTimes(on: day, from: startTime, to: finishTime).start }
    var finish: Date { shiftTimes(on: day, from: startTime, to: finishTime).end }

    var hours: Double { finish.timeIntervalSince(start) / 3600 }

    func load() {
        guard case .logPastShift = purpose else { return }
        do {
            // A past shift can be at a job the student has since left.
            employers = try services.reviewJobs.execute().allEmployers
            employerID = employerID ?? employers.first?.id
        } catch {
            problem = ProblemMessage(error)
        }
    }

    func save() -> Bool {
        let subject: PastShiftRequest.Subject
        switch purpose {
        case .logPastShift:
            guard let employerID else { return false }
            subject = .newShift(employerID: employerID)
        case let .enterMissedTimes(listing):
            subject = .missedShift(listing.id)
        case let .correct(listing):
            subject = .workedShift(listing.id)
        }
        do {
            try services.logPastShift.execute(PastShiftRequest(subject: subject, start: start, finish: finish))
            return true
        } catch {
            problem = ProblemMessage(error)
            return false
        }
    }
}
