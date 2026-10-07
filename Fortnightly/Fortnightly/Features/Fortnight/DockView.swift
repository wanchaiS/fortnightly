import FortnightlyKit
import SwiftUI

/// The one thing to do now, pinned under the board.
struct DockView: View {
    let currentShift: CurrentShift
    let fortnightOverLimit: FortnightWorkSummary?
    let actions: ShiftActions
    let enterTimes: (ShiftListing) -> Void
    let rosterShift: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    .font(.headline)
                // At the largest text sizes the dock keeps only what to do, leaving room for the board.
                if !typeSize.isAccessibilitySize {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            buttons
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(
            Palette.shell
                .clipShape(.rect(topLeadingRadius: 18, topTrailingRadius: 18))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var headline: String {
        switch currentShift {
        case let .clockOutDue(listing): "\(listing.employerName) was rostered to finish at \(listing.shift.rosteredFinish.timeText)"
        case let .onShift(listing): "On shift at \(listing.employerName)"
        case let .clockInDue(listing): "\(listing.employerName) started at \(listing.shift.rosteredStart.timeText)"
        case let .missed(listing): "\(listing.employerName), \(listing.shift.rosteredStart.dayText) finished without a clock-in"
        case let .next(listing): "Next: \(listing.employerName) \(nextShiftWhen(listing.shift))"
        case .nothingRostered: "Nothing rostered"
        }
    }

    private var detail: String {
        switch currentShift {
        case .clockOutDue:
            return "You're still clocked in."
        case let .onShift(listing):
            return "Since \((listing.shift.clockedInAt ?? listing.shift.rosteredStart).timeText). Rostered until \(listing.shift.rosteredFinish.timeText)."
        case let .clockInDue(listing):
            return "You haven't clocked in. Rostered until \(listing.shift.rosteredFinish.timeText)."
        case let .missed(listing):
            let hours = listing.shift.rosteredFinish.timeIntervalSince(listing.shift.rosteredStart) / 3600
            return "Its \(hours.hoursDescription) hours still count until you answer. Did you work it?"
        case let .next(listing):
            if let over = fortnightOverLimit {
                return "\(over.fortnight.datesDescription) is over the limit. Ask to swap or shorten a shift in it."
            }
            return "Rostered until \(listing.shift.rosteredFinish.timeText)."
        case .nothingRostered:
            return "Your next shift will appear here."
        }
    }

    @ViewBuilder private var buttons: some View {
        switch currentShift {
        case let .clockOutDue(listing):
            buttonPair {
                Button("Finished \(listing.shift.rosteredFinish.timeText)") { actions.clockOut(listing.shift, finishedAt: .asRostered) }
                    .buttonStyle(DockButtonStyle(kind: .actNow))
                Button("Just now") { actions.clockOut(listing.shift, finishedAt: .now) }
                    .buttonStyle(DockButtonStyle(kind: .secondary))
            }
        case let .onShift(listing):
            Button("Clock out now") { actions.clockOut(listing.shift, finishedAt: .now) }
                .buttonStyle(DockButtonStyle(kind: .plain))
        case let .clockInDue(listing):
            buttonPair {
                Button("Started \(listing.shift.rosteredStart.timeText)") { actions.clockIn(listing.shift, startedAt: .asRostered) }
                    .buttonStyle(DockButtonStyle(kind: .actNow))
                Button("Just now") { actions.clockIn(listing.shift, startedAt: .now) }
                    .buttonStyle(DockButtonStyle(kind: .secondary))
            }
        case let .missed(listing):
            buttonPair {
                Button("Yes, enter my times") { enterTimes(listing) }
                    .buttonStyle(DockButtonStyle(kind: .plain))
                Button("No, I didn't") { actions.markNotWorked(listing.shift) }
                    .buttonStyle(DockButtonStyle(kind: .secondary))
            }
        case .next:
            EmptyView()
        case .nothingRostered:
            Button("Roster a shift", action: rosterShift)
                .buttonStyle(DockButtonStyle(kind: .plain))
        }
    }

    /// Side by side, or stacked when large text doesn't fit.
    private func buttonPair(@ViewBuilder _ content: () -> some View) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8, content: content)
            VStack(spacing: 8, content: content)
        }
    }

    private func nextShiftWhen(_ shift: Shift) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(shift.rosteredStart) { return "today at \(shift.rosteredStart.timeText)" }
        if calendar.isDateInTomorrow(shift.rosteredStart) { return "tomorrow at \(shift.rosteredStart.timeText)" }
        return "on \(shift.rosteredStart.dayText) at \(shift.rosteredStart.timeText)"
    }
}

struct DockButtonStyle: ButtonStyle {
    enum Kind {
        /// Yellow: reserved for "act now".
        case actNow
        case plain
        case secondary
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.bold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 6)
            .foregroundStyle(kind == .secondary ? Color.white : Palette.onActNow)
            .background(background, in: .rect(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }

    private var background: Color {
        switch kind {
        case .actNow: Palette.actNow
        case .plain: .white
        case .secondary: .white.opacity(0.14)
        }
    }
}
