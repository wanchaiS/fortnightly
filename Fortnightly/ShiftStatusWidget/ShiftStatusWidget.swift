import AppIntents
import FortnightlyKit
import SwiftUI
import WidgetKit

struct ShiftStatusEntry: TimelineEntry {
    let date: Date
    /// `nil` when the shared store couldn't be read.
    let currentShift: CurrentShift?
    let fortnight: FortnightWorkSummary?
    let slices: [DonutSlice]
}

struct ShiftStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShiftStatusEntry {
        ShiftStatusEntry(date: .now, currentShift: .nothingRostered, fortnight: nil, slices: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftStatusEntry) -> Void) {
        completion(entry(at: .now))
    }

    /// One entry, refreshed when the shift's next rostered start or finish changes what the widget asks.
    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftStatusEntry>) -> Void) {
        let entry = entry(at: .now)
        let nextChange: Date? = switch entry.currentShift {
        case let .onShift(listing), let .clockInDue(listing): listing.shift.rosteredFinish
        case let .next(listing): listing.shift.rosteredStart
        default: nil
        }
        completion(Timeline(entries: [entry], policy: .after(nextChange ?? .now.addingTimeInterval(3600))))
    }

    private func entry(at date: Date) -> ShiftStatusEntry {
        do {
            let services = try FortnightlyServices.appGroup().asOf(date)
            let review = try services.reviewFortnightHours.execute(on: date)
            // Of the two fortnights containing today, show the one closer to the limit.
            let fortnight = [review.fortnightStartedLastWeek, review.fortnightStartingThisWeek].max { $0.hoursTowardLimit < $1.hoursTowardLimit }!
            let employers = try services.reviewJobs.execute().allEmployers
            return ShiftStatusEntry(
                date: date,
                currentShift: try services.reviewCurrentShift.execute(),
                fortnight: fortnight,
                slices: DonutSlice.slices(for: fortnight, employers: employers)
            )
        } catch {
            return ShiftStatusEntry(date: date, currentShift: nil, fortnight: nil, slices: [])
        }
    }
}

struct ShiftStatusWidgetView: View {
    let entry: ShiftStatusEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        default: small
        }
    }

    private var hours: Double { entry.fortnight?.hoursTowardLimit ?? 0 }
    private var hoursText: String { "\(hours.hoursDescription) of \(WorkLimitPolicy.hoursPerFortnight.hoursDescription) h" }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                FortnightDonut(slices: entry.slices, lineWidth: 8)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 0) {
                    if case let .clockInDue(listing) = entry.currentShift {
                        // Who to clock in for matters more than the total here.
                        Text(listing.employerName).font(.subheadline.weight(.bold)).lineLimit(2)
                        Text("Not clocked in").font(.caption).foregroundStyle(Palette.muted)
                    } else {
                        Text(hours.hoursDescription).font(.headline).monospacedDigit()
                        Text("of \(WorkLimitPolicy.hoursPerFortnight.hoursDescription) h").font(.caption).foregroundStyle(Palette.muted)
                    }
                }
            }
            Spacer(minLength: 0)
            smallStatus
        }
        .foregroundStyle(Palette.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private var smallStatus: some View {
        switch entry.currentShift {
        case let .clockInDue(listing):
            Button(intent: ClockInIntent(shiftID: listing.id, atRosteredStart: true)) {
                Text("Started \(listing.shift.rosteredStart.formatted(date: .omitted, time: .shortened))")
            }
            .buttonStyle(WidgetButtonStyle(fill: Palette.actNow, text: Palette.onActNow))
            Button(intent: ClockInIntent(shiftID: listing.id, atRosteredStart: false)) { Text("Just now") }
                .buttonStyle(WidgetButtonStyle(fill: Palette.track, text: Palette.ink))
        case let .onShift(listing):
            caption("On shift at \(listing.employerName) · \(Text(listing.shift.clockedInAt ?? listing.shift.rosteredStart, style: .timer))")
            Button(intent: ClockOutIntent(shiftID: listing.id, atRosteredFinish: false)) { Text("Clock out") }
                .buttonStyle(WidgetButtonStyle(fill: Palette.ink, text: Palette.card))
        case let .clockOutDue(listing):
            caption("Still clocked in at \(listing.employerName)")
            Button(intent: ClockOutIntent(shiftID: listing.id, atRosteredFinish: true)) {
                Text("Finished \(listing.shift.rosteredFinish.formatted(date: .omitted, time: .shortened))")
            }
            .buttonStyle(WidgetButtonStyle(fill: Palette.actNow, text: Palette.onActNow))
        case let .missed(listing):
            title(listing.employerName, "Not clocked in on \(listing.shift.rosteredStart.formatted(.dateTime.weekday(.abbreviated))). Did you work it?")
        case let .next(listing):
            title(listing.employerName, "Next shift · \(listing.shift.rosteredStart.formatted(.dateTime.weekday(.abbreviated).hour().minute()))")
        case .nothingRostered:
            title("No shifts rostered", "Add your roster in Fortnightly.")
        case nil:
            title("Shifts unavailable", "Open Fortnightly to see your shifts.")
        }
    }

    private func caption(_ text: LocalizedStringKey) -> some View {
        Text(text).font(.caption2).foregroundStyle(Palette.muted).lineLimit(2)
    }

    private func title(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.subheadline.weight(.bold)).lineLimit(1)
            Text(detail).font(.caption).foregroundStyle(Palette.muted).lineLimit(2)
        }
    }

    // MARK: Lock Screen (drawn in one colour by iOS, so words carry the state)

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch entry.currentShift {
            case let .clockInDue(listing):
                Text(listing.employerName).font(.headline).widgetAccentable()
                Text("Not clocked in · \(listing.shift.rosteredStart.formatted(date: .omitted, time: .shortened))")
            case let .onShift(listing):
                Text("On shift · \(listing.employerName)").font(.headline).widgetAccentable()
                Text(listing.shift.clockedInAt ?? listing.shift.rosteredStart, style: .timer)
            case let .clockOutDue(listing):
                Text(listing.employerName).font(.headline).widgetAccentable()
                Text("Still clocked in")
            case let .missed(listing):
                Text(listing.employerName).font(.headline).widgetAccentable()
                Text("Not clocked in · did you work it?")
            case let .next(listing):
                Text("Next: \(listing.employerName)").font(.headline).widgetAccentable()
                Text(listing.shift.rosteredStart, format: .dateTime.weekday(.abbreviated).hour().minute())
            case .nothingRostered, nil:
                Text("Fortnightly").font(.headline).widgetAccentable()
                Text("No shifts rostered")
            }
            Text(hoursText).monospacedDigit()
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var circular: some View {
        Gauge(value: min(hours, WorkLimitPolicy.hoursPerFortnight), in: 0 ... WorkLimitPolicy.hoursPerFortnight) {
            Text("Hours")
        } currentValueLabel: {
            Text(Int(hours.rounded(.down)), format: .number)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel(hoursText)
    }
}

private struct WidgetButtonStyle: ButtonStyle {
    let fill: Color
    let text: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: 28)
            .foregroundStyle(text)
            .background(fill, in: .rect(cornerRadius: 9))
    }
}

struct ShiftStatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: ShiftStatusWidgetKind.identifier, provider: ShiftStatusProvider()) { entry in
            ShiftStatusWidgetView(entry: entry)
                .containerBackground(Palette.card, for: .widget)
        }
        .configurationDisplayName("Shift status")
        .description("Your fortnight's hours, and a nudge to clock in or out.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryCircular])
    }
}
