// Milestone 1 spike: proves the App Group store, widget and notification extension work end to end.
// Talks to repositories directly (no use cases yet). Delete this folder when the Today screen lands.

import FortnightlyKit
import Foundation
import Observation
import SwiftUI
import UserNotifications
import WidgetKit

@Observable
final class SpikePanelModel {
    struct UpcomingShift: Identifiable {
        let shift: Shift
        let employerName: String
        var id: Shift.ID { shift.id }
    }

    private(set) var storeStatus = "Opening the shared shift store…"
    private(set) var upcoming: [UpcomingShift] = []
    private(set) var promptStatus = ""
    private(set) var widgetProbe = ""
    private(set) var pendingReminders: [String] = []

    private var shifts: (any ShiftRepository)?
    private var employers: (any EmployerRepository)?

    init() {
        switch ShiftStore.appGroup {
        case let .success(store):
            shifts = CoreDataShiftRepository(store: store)
            employers = CoreDataEmployerRepository(store: store)
            storeStatus = "Shared shift store open ✓"
        case let .failure(error):
            storeStatus = "Shared shift store unavailable: \(error)"
        }
        if ProcessInfo.processInfo.arguments.contains("-spikeSeed") {
            saveTestShift()
        }
        refresh()
    }

    func saveTestShift() {
        guard let shifts, let employers else { return }
        do {
            let cafe = try employers.employers(includingArchived: false).first { $0.name == "Café Roma" }
                ?? Employer(name: "Café Roma", colour: .violet, payCycleStartsOn: .now)
            try employers.save(cafe)
            let start = Date.now.addingTimeInterval(2 * 60)
            try shifts.save(Shift(employerID: cafe.id, rosteredStart: start, rosteredFinish: start.addingTimeInterval(5.5 * 3600)))
            WidgetCenter.shared.reloadTimelines(ofKind: ShiftStatusWidgetKind.identifier)
            refresh()
        } catch {
            storeStatus = "Couldn't save the test shift: \(error)"
        }
    }

    func scheduleStartPrompt() async {
        guard let next = upcoming.first else {
            promptStatus = "Save a test shift first."
            return
        }
        let center = UNUserNotificationCenter.current()
        do {
            guard try await center.requestAuthorization(options: [.alert, .sound]) else {
                promptStatus = "Notifications are off for Fortnightly. Turn them on in Settings → Notifications."
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "\(next.employerName) shift starting"
            content.body = "Clock in?"
            content.categoryIdentifier = ShiftPromptCategory.shiftStart
            content.userInfo = [ShiftPromptCategory.shiftIDKey: next.shift.id.uuidString]
            try await center.add(UNNotificationRequest(
                identifier: "spike.start.\(next.shift.id)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            ))

            let probe = UNMutableNotificationContent()
            probe.title = "Spike probe (the widget should cancel this)"
            try await center.add(UNNotificationRequest(
                identifier: SpikeProbe.reminderIdentifier,
                content: probe,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
            ))
            WidgetCenter.shared.reloadTimelines(ofKind: ShiftStatusWidgetKind.identifier)
            promptStatus = "Start prompt arrives in 10 s. Press ⌘L to lock the Simulator, then long-press the prompt."
        } catch {
            promptStatus = "Couldn't schedule the prompt: \(error.localizedDescription)"
        }
        await refreshPendingReminders()
    }

    func refresh() {
        if let shifts, let employers {
            do {
                upcoming = try shifts.upcomingShifts(after: .now).map { shift in
                    UpcomingShift(shift: shift, employerName: try employers.employer(withID: shift.employerID)?.name ?? "Unknown employer")
                }
            } catch {
                storeStatus = "Couldn't read shifts: \(error)"
            }
        }
        widgetProbe = AppGroup.sharedDefaults?.string(forKey: SpikeProbe.resultKey)
            ?? "Widget hasn't run the probe yet. Add the Shift status widget to the Home Screen."
        Task { await refreshPendingReminders() }
    }

    private func refreshPendingReminders() async {
        pendingReminders = await UNUserNotificationCenter.current().pendingNotificationRequests().map(\.identifier).sorted()
    }
}

struct SpikePanel: View {
    @State private var model = SpikePanelModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                Section("Shared store") {
                    Text(model.storeStatus)
                }
                Section("Upcoming shifts") {
                    if model.upcoming.isEmpty {
                        Text("No shifts rostered yet.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.upcoming) { row in
                        VStack(alignment: .leading) {
                            Text(row.employerName).font(.headline)
                            Text("\(row.shift.rosteredStart.formatted(date: .abbreviated, time: .shortened)) – \(row.shift.rosteredFinish.formatted(date: .omitted, time: .shortened))")
                                .font(.subheadline)
                        }
                    }
                }
                Section("Actions") {
                    Button("Save test shift (Café Roma, starts in 2 min)") { model.saveTestShift() }
                    Button("Schedule start prompt in 10 s") { Task { await model.scheduleStartPrompt() } }
                    if !model.promptStatus.isEmpty {
                        Text(model.promptStatus).font(.footnote)
                    }
                }
                Section("Widget reminder probe") {
                    Text(model.widgetProbe).font(.footnote)
                    Text("Pending: \(model.pendingReminders.isEmpty ? "none" : model.pendingReminders.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Milestone 1 spike")
            .refreshable { model.refresh() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refresh() }
        }
    }
}
