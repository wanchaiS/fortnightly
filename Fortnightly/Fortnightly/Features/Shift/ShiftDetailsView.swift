import FortnightlyKit
import SwiftUI

/// One shift: rostered and actual times side by side, and what can be done with it now.
struct ShiftDetailsView: View {
    private enum Stage {
        case upcoming, clockInDue, onShift, clockOutDue, missed, worked, notWorked
    }

    let listing: ShiftListing
    let services: FortnightlyServices
    let now: Date
    let onDone: () -> Void
    @State private var actions: ShiftActions
    @State private var timesSheet: ShiftTimesSheet.Purpose?
    @State private var changingRoster = false

    init(listing: ShiftListing, services: FortnightlyServices, now: Date, onDone: @escaping () -> Void) {
        self.listing = listing
        self.services = services
        self.now = now
        self.onDone = onDone
        let actions = ShiftActions(services: services)
        actions.onChange = onDone
        _actions = State(initialValue: actions)
    }

    private var shift: Shift { listing.shift }

    private var stage: Stage {
        switch shift.status {
        case .worked: .worked
        case .notWorked: .notWorked
        case .onShift: shift.rosteredFinish <= now ? .clockOutDue : .onShift
        case .rostered:
            if shift.rosteredFinish <= now { .missed }
            else if shift.rosteredStart <= now { .clockInDue }
            else { .upcoming }
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 2) {
                    Text(listing.employerName).font(.title2.bold())
                    Text(subtitle).font(.subheadline).foregroundStyle(Palette.muted)
                }
                .foregroundStyle(Palette.ink)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 4))
            }
            Section {
                times
            } footer: {
                if let note = timesNote { Text(note) }
            }
            actionSection
        }
        .scrollContentBackground(.hidden)
        .background(Palette.ground)
        .navigationTitle("Shift details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: onDone)
            }
        }
        .tint(Palette.tint)
        .sheet(item: $timesSheet) { purpose in
            ShiftTimesSheet(purpose: purpose, services: services, onDone: onDone)
        }
        .sheet(isPresented: $changingRoster) {
            RosterShiftSheet(services: services, editing: listing, onDone: onDone)
        }
        .problemAlert($actions.problem)
    }

    private var subtitle: String {
        let day = shift.rosteredStart.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        let state = switch stage {
        case .upcoming: "rostered"
        case .clockInDue: "started, not clocked in"
        case .onShift, .clockOutDue: "on shift"
        case .missed: "finished without a clock-in"
        case .worked: "worked"
        case .notWorked: "not working"
        }
        return "\(day) · \(state)"
    }

    @ViewBuilder private var times: some View {
        switch stage {
        case .upcoming:
            LabeledContent("Starts", value: shift.rosteredStart.timeText)
            LabeledContent("Finishes", value: shift.rosteredFinish.timeText)
            LabeledContent("Reminders", value: "\(shift.rosteredStart.timeText) and \(shift.rosteredFinish.timeText)")
        case .clockInDue, .missed, .notWorked:
            LabeledContent("Rostered", value: shift.rosteredTimesText)
            LabeledContent("Clocked in", value: "No")
        case .onShift, .clockOutDue:
            LabeledContent("Rostered", value: shift.rosteredTimesText)
            LabeledContent("Clocked in", value: (shift.clockedInAt ?? shift.rosteredStart).timeText)
        case .worked:
            LabeledContent("Rostered", value: shift.rosteredTimesText)
            LabeledContent("Clocked in", value: (shift.clockedInAt ?? shift.rosteredStart).timeText)
            LabeledContent("Clocked out", value: (shift.clockedOutAt ?? shift.rosteredFinish).timeText)
            LabeledContent("Hours worked", value: workedHours.hoursDescription)
        }
    }

    private var rosteredHours: Double { shift.rosteredFinish.timeIntervalSince(shift.rosteredStart) / 3600 }

    private var workedHours: Double {
        guard let clockedInAt = shift.clockedInAt, let clockedOutAt = shift.clockedOutAt else { return 0 }
        return clockedOutAt.timeIntervalSince(clockedInAt) / 3600
    }

    private var timesNote: String? {
        switch stage {
        case .missed:
            return "Until you answer, its \(rosteredHours.hoursDescription) hours still count toward your fortnight."
        case .notWorked:
            return "Its hours don't count toward your fortnight, and it has no reminders."
        case .worked:
            // The difference is what the student checks against their payslip.
            let extraMinutes = Int(((workedHours - rosteredHours) * 60).rounded())
            if extraMinutes > 0 { return "You worked \(extraMinutes) minutes more than rostered. Check they're on your payslip." }
            if extraMinutes < 0 { return "You worked \(-extraMinutes) minutes less than rostered." }
            return nil
        default:
            return nil
        }
    }

    @ViewBuilder private var actionSection: some View {
        switch stage {
        case .upcoming:
            Section {
                Button("Change times") { changingRoster = true }
                Button("Not working this shift", role: .destructive) { actions.markNotWorked(shift) }
            } footer: {
                Text("Use \"Not working\" when a shift is swapped or cancelled. Its hours stop counting and its reminders stop.")
            }
        case .clockInDue:
            Section {
                Button("Started \(shift.rosteredStart.timeText)") { actions.clockIn(shift, startedAt: .asRostered) }
                Button("Started just now") { actions.clockIn(shift, startedAt: .now) }
                Button("Not working this shift", role: .destructive) { actions.markNotWorked(shift) }
            }
        case .onShift:
            Section {
                Button("Clock out now") { actions.clockOut(shift, finishedAt: .now) }
            }
        case .clockOutDue:
            Section {
                Button("Finished \(shift.rosteredFinish.timeText)") { actions.clockOut(shift, finishedAt: .asRostered) }
                Button("Finished just now") { actions.clockOut(shift, finishedAt: .now) }
            }
        case .missed:
            Section("Did you work this shift?") {
                Button("Yes, enter my times") { timesSheet = .enterMissedTimes(listing) }
                Button("No, I didn't work it", role: .destructive) { actions.markNotWorked(shift) }
            }
        case .worked:
            Section {
                Button("Correct times") { timesSheet = .correct(listing) }
            }
        case .notWorked:
            Section {
                if shift.rosteredFinish > now {
                    Button("Put back on my roster") { changingRoster = true }
                } else {
                    Button("I worked it, enter my times") { timesSheet = .enterMissedTimes(listing) }
                }
            }
        }
    }
}
