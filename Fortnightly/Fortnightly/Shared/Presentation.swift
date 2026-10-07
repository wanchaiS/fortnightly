import FortnightlyKit
import SwiftUI

/// An error as the student reads it: what went wrong, then what to do next.
struct ProblemMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    init(_ error: Error) {
        title = error.localizedDescription
        message = (error as? LocalizedError)?.recoverySuggestion ?? ""
    }

    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

extension View {
    func problemAlert(_ problem: Binding<ProblemMessage?>) -> some View {
        alert(
            problem.wrappedValue?.title ?? "",
            isPresented: Binding(get: { problem.wrappedValue != nil }, set: { if !$0 { problem.wrappedValue = nil } }),
            actions: { Button("OK") {} },
            message: { Text(problem.wrappedValue?.message ?? "") }
        )
    }

    /// The navy shell behind the navigation bar, with a white title.
    func navyNavigationBar(title: String, showsTitle: Bool = true) -> some View {
        modifier(NavyNavigationBar(title: title, showsTitle: showsTitle))
    }
}

private struct NavyNavigationBar: ViewModifier {
    let title: String
    let showsTitle: Bool
    @Environment(\.colorScheme) private var appearance

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.shell(for: appearance), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                // On iOS 26 the system title stays dark on a coloured bar, so the bar draws its own.
                ToolbarItem(placement: .principal) {
                    Text(title).font(.headline).foregroundStyle(.white).opacity(showsTitle ? 1 : 0)
                }
            }
    }
}

extension Date {
    /// "5:00 pm"
    var timeText: String { formatted(date: .omitted, time: .shortened) }
    /// "Sat 17"
    var dayText: String { formatted(.dateTime.weekday(.abbreviated).day()) }
}

extension Shift {
    /// "5:00 pm – 10:30 pm"
    var rosteredTimesText: String { "\(rosteredStart.timeText) – \(rosteredFinish.timeText)" }
}

/// A shift's start and finish from the day and two times of day picked in a form.
/// A finish at or before the start means the shift ends after midnight, on the next day.
func shiftTimes(on day: Date, from startTime: Date, to finishTime: Date) -> DateInterval {
    let calendar = Calendar.current
    func time(_ time: Date) -> Date {
        let parts = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0, second: 0, of: day)!
    }
    let start = time(startTime)
    let finish = time(finishTime)
    return DateInterval(start: start, end: finish > start ? finish : calendar.date(byAdding: .day, value: 1, to: finish)!)
}
