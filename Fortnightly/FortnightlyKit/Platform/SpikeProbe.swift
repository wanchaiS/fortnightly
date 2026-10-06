// Milestone 1 spike only: answers "can the widget extension cancel the app's pending reminders?"
// Delete together with the app's Spike folder once the answer is recorded in DECISIONS.md.
public enum SpikeProbe {
    /// A far-future reminder the app schedules and the widget tries to cancel.
    public static let reminderIdentifier = "spike.probe"
    /// Shared-defaults key where the widget writes what it saw.
    public static let resultKey = "spike.widgetProbeResult"
}
