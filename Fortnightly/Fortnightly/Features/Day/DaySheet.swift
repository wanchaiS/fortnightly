import FortnightlyKit
import SwiftUI

/// One day of the fortnight: its shifts with their times, and a way to add another.
struct DaySheet: View {
    let day: WorkDay
    let services: FortnightlyServices
    let now: Date
    let onDone: () -> Void
    @State private var adding: ShiftTimesSheet.Purpose?
    @State private var rostering = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if day.shifts.isEmpty {
                        Text("No shifts on this day.")
                            .foregroundStyle(Palette.muted)
                    }
                    ForEach(day.shifts) { listing in
                        NavigationLink {
                            ShiftDetailsView(listing: listing, services: services, now: now, onDone: onDone)
                        } label: {
                            ShiftRow(listing: listing, now: now)
                        }
                    }
                } footer: {
                    Text(footer)
                }
                Section {
                    if !isPast {
                        Button("Roster a shift on \(day.date.dayText)", systemImage: "plus") { rostering = true }
                    }
                    if day.date <= now {
                        Button("Log a past shift on \(day.date.dayText)", systemImage: "clock.arrow.circlepath") {
                            adding = .logPastShift(day: day.date)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.ground)
            .navigationTitle(day.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
        }
        .tint(Palette.tint)
        .sheet(isPresented: $rostering) {
            RosterShiftSheet(services: services, day: day.date, onDone: onDone)
        }
        .sheet(item: $adding) { purpose in
            ShiftTimesSheet(purpose: purpose, services: services, onDone: onDone)
        }
    }

    private var isPast: Bool {
        Calendar.current.date(byAdding: .day, value: 1, to: day.date)! <= now
    }

    /// Every day belongs to two work fortnights: one starting this week's Monday and one starting last week's.
    private var footer: String {
        let fortnights = WorkFortnight.containing(day.date, calendar: .current)
        let style = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)
        var lines = ["\(day.hours.hoursDescription) hours on this day. It's in the fortnights from \(fortnights.startedLastWeek.startsOn.formatted(style)) and \(fortnights.startingThisWeek.startsOn.formatted(style))."]
        if day.isInCourseBreak {
            lines.append("This day is in a course break, so its hours don't count toward the limit.")
        }
        return lines.joined(separator: " ")
    }
}

/// A shift in a list: its employer, what happened, its hours.
struct ShiftRow: View {
    let listing: ShiftListing
    let now: Date

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(listing.employerColour.color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(listing.employerName).foregroundStyle(Palette.ink)
                Text(status).font(.subheadline).foregroundStyle(Palette.muted)
            }
            Spacer()
            Text("\(DayBarSegment(listing: listing, now: now).hours.hoursDescription) h")
                .monospacedDigit()
                .foregroundStyle(listing.shift.status == .notWorked ? Palette.muted : Palette.ink)
                .strikethrough(listing.shift.status == .notWorked)
        }
    }

    private var status: String {
        let shift = listing.shift
        switch shift.status {
        case .worked:
            return "Worked \((shift.clockedInAt ?? shift.rosteredStart).timeText) – \((shift.clockedOutAt ?? shift.rosteredFinish).timeText)"
        case .onShift:
            return "On shift since \((shift.clockedInAt ?? shift.rosteredStart).timeText)"
        case .notWorked:
            return "Not working · was \(shift.rosteredTimesText)"
        case .rostered:
            if shift.rosteredFinish <= now { return "Not clocked in · rostered \(shift.rosteredTimesText)" }
            if shift.rosteredStart <= now { return "Started \(shift.rosteredStart.timeText) · not clocked in" }
            return "Rostered \(shift.rosteredTimesText)"
        }
    }
}
