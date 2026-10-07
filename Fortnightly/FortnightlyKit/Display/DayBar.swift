import SwiftUI

/// One shift on a day bar. Its form carries its state, so state never depends on colour alone.
public struct DayBarSegment: Identifiable, Equatable, Sendable {
    public enum Form: Sendable {
        case worked
        case rostered
        /// Started without a clock-in: ringed in the "act now" yellow.
        case clockInDue
        case notWorked
        /// The shift being added in the roster sheet.
        case adding
    }

    public let id: Shift.ID
    public let colour: EmployerColour
    public let hours: Double
    public let form: Form

    public init(id: Shift.ID = UUID(), colour: EmployerColour, hours: Double, form: Form) {
        self.id = id
        self.colour = colour
        self.hours = hours
        self.form = form
    }

    public init(listing: ShiftListing, now: Date) {
        let shift = listing.shift
        let form: Form = switch shift.status {
        case .worked, .onShift: .worked
        case .notWorked: .notWorked
        case .rostered: shift.rosteredStart <= now && now < shift.rosteredFinish ? .clockInDue : .rostered
        }
        // A shift not worked keeps its rostered length, struck through.
        let time = shift.timeTowardWorkLimit(asOf: now) ?? DateInterval(start: shift.rosteredStart, end: shift.rosteredFinish)
        self.init(id: shift.id, colour: listing.employerColour, hours: time.duration / 3600, form: form)
    }
}

/// A day as a 12-hour bar: room for two shifts side by side. A longer day stretches the scale.
public struct DayBar: View {
    private let segments: [DayBarSegment]
    private let minimumHoursAcross: Double

    public init(segments: [DayBarSegment], minimumHoursAcross: Double = 12) {
        self.segments = segments
        self.minimumHoursAcross = minimumHoursAcross
    }

    public var body: some View {
        GeometryReader { geometry in
            let hoursAcross = max(minimumHoursAcross, segments.reduce(0) { $0 + $1.hours })
            HStack(spacing: 2) {
                ForEach(segments) { segment in
                    SegmentShape(segment: segment)
                        .frame(width: max(4, geometry.size.width * segment.hours / hoursAcross - 2))
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 16)
        .background(Palette.track, in: .rect(cornerRadius: 5))
        .clipShape(.rect(cornerRadius: 5))
        .accessibilityHidden(true)
    }
}

private struct SegmentShape: View {
    let segment: DayBarSegment

    var body: some View {
        let colour = segment.colour.color
        let shape = RoundedRectangle(cornerRadius: 4)
        switch segment.form {
        case .worked:
            shape.fill(colour)
        case .rostered, .clockInDue:
            shape.fill(colour.opacity(0.2))
                .overlay(Hatching().stroke(colour.opacity(0.55), lineWidth: 2.5).clipShape(shape))
                .overlay(shape.strokeBorder(segment.form == .clockInDue ? Palette.actNow : colour, lineWidth: segment.form == .clockInDue ? 2.5 : 1.5))
        case .notWorked:
            shape.strokeBorder(colour.opacity(0.5), lineWidth: 1.5)
                .overlay(Rectangle().fill(colour.opacity(0.7)).frame(height: 1.5))
        case .adding:
            shape.fill(colour.opacity(0.15))
                .overlay(shape.strokeBorder(colour, style: StrokeStyle(lineWidth: 2, dash: [4, 3])))
        }
    }
}

/// Diagonal stripes: the "light hatched" form of a rostered shift.
private struct Hatching: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            var x = rect.minX - rect.height
            while x < rect.maxX {
                path.move(to: CGPoint(x: x, y: rect.maxY))
                path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
                x += 6
            }
        }
    }
}

/// A day on the board: its label, its bar, its total.
public struct DayRow: View {
    private let date: Date
    private let segments: [DayBarSegment]
    private let hours: Double
    private let isToday: Bool
    private let needsAnswer: Bool
    @ScaledMetric(relativeTo: .subheadline) private var labelWidth = 76
    @ScaledMetric(relativeTo: .subheadline) private var hoursWidth = 44

    public init(date: Date, segments: [DayBarSegment], hours: Double, isToday: Bool = false, needsAnswer: Bool = false) {
        self.date = date
        self.segments = segments
        self.hours = hours
        self.isToday = isToday
        self.needsAnswer = needsAnswer
    }

    public var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Text(date, format: .dateTime.weekday(.abbreviated))
                    .fontWeight(.semibold)
                    .foregroundStyle(isToday ? Palette.card : segments.isEmpty ? Palette.muted : Palette.ink)
                    .padding(.horizontal, isToday ? 6 : 0)
                    .background(isToday ? Palette.ink : .clear, in: .rect(cornerRadius: 7))
                Text(date, format: .dateTime.day())
                    .monospacedDigit()
                if needsAnswer {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(.white, WorkLimitStatus.approachingLimit.color)
                }
            }
            .foregroundStyle(segments.isEmpty ? Palette.muted : Palette.ink)
            .frame(width: labelWidth, alignment: .leading)
            DayBar(segments: segments)
            Text(hours > 0 ? hours.hoursDescription : "–")
                .monospacedDigit()
                .fontWeight(hours > 0 ? .semibold : .regular)
                .foregroundStyle(hours > 0 ? Palette.ink : Palette.muted)
                .frame(width: hoursWidth, alignment: .trailing)
        }
        .font(.subheadline)
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [date.formatted(.dateTime.weekday(.wide).day().month(.wide))]
        if isToday { parts.append("today") }
        parts.append(hours > 0 ? "\(hours.hoursDescription) hours" : "no shifts")
        if needsAnswer { parts.append("a shift needs your answer") }
        return parts.joined(separator: ", ")
    }
}
