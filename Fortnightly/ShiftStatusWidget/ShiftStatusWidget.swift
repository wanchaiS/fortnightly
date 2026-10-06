import FortnightlyKit
import Foundation
import SwiftUI
import UserNotifications
import WidgetKit

struct ShiftStatusEntry: TimelineEntry {
    struct NextShift {
        let employerName: String
        let rosteredStart: Date
        let rosteredFinish: Date
    }

    let date: Date
    let nextShift: NextShift?
    let problem: String?
}

struct ShiftStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShiftStatusEntry {
        ShiftStatusEntry(
            date: .now,
            nextShift: .init(employerName: "Café Roma", rosteredStart: .now, rosteredFinish: .now.addingTimeInterval(5.5 * 3600)),
            problem: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftStatusEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftStatusEntry>) -> Void) {
        runSpikeReminderProbe()
        completion(Timeline(entries: [currentEntry()], policy: .after(.now.addingTimeInterval(15 * 60))))
    }

    private func currentEntry() -> ShiftStatusEntry {
        do {
            let store = try ShiftStore.appGroup.get()
            guard let shift = try CoreDataShiftRepository(store: store).upcomingShifts(after: .now).first else {
                return ShiftStatusEntry(date: .now, nextShift: nil, problem: nil)
            }
            let employerName = try CoreDataEmployerRepository(store: store).employer(withID: shift.employerID)?.name
            return ShiftStatusEntry(
                date: .now,
                nextShift: .init(
                    employerName: employerName ?? "Unknown employer",
                    rosteredStart: shift.rosteredStart,
                    rosteredFinish: shift.rosteredFinish
                ),
                problem: nil
            )
        } catch {
            return ShiftStatusEntry(date: .now, nextShift: nil, problem: "Open Fortnightly to see your shifts")
        }
    }

    /// Milestone 1 spike: can this extension see and cancel the app's pending reminders?
    private func runSpikeReminderProbe() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let sawProbe = requests.contains { $0.identifier == SpikeProbe.reminderIdentifier }
            center.removePendingNotificationRequests(withIdentifiers: [SpikeProbe.reminderIdentifier])
            let time = Date.now.formatted(date: .omitted, time: .standard)
            let summary = "Widget at \(time): saw \(requests.count) pending reminder(s); probe \(sawProbe ? "found, removal requested" : "not found")"
            AppGroup.sharedDefaults?.set(summary, forKey: SpikeProbe.resultKey)
        }
    }
}

struct ShiftStatusWidgetView: View {
    let entry: ShiftStatusEntry

    var body: some View {
        if let problem = entry.problem {
            Text(problem)
                .font(.caption)
        } else if let shift = entry.nextShift {
            VStack(alignment: .leading, spacing: 2) {
                Text("Next shift")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(shift.employerName)
                    .font(.headline)
                Text(shift.rosteredStart, format: .dateTime.weekday(.abbreviated).hour().minute())
                    .font(.subheadline)
                Text("until \(shift.rosteredFinish.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("No shifts rostered")
                .font(.headline)
        }
    }
}

struct ShiftStatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: ShiftStatusWidgetKind.identifier, provider: ShiftStatusProvider()) { entry in
            ShiftStatusWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Shift status")
        .description("Your next shift and whether you're clocked in.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    ShiftStatusWidget()
} timeline: {
    ShiftStatusEntry(
        date: .now,
        nextShift: .init(employerName: "Café Roma", rosteredStart: .now, rosteredFinish: .now.addingTimeInterval(5.5 * 3600)),
        problem: nil
    )
    ShiftStatusEntry(date: .now, nextShift: nil, problem: nil)
}
