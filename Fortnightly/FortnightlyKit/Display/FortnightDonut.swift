import SwiftUI

public struct DonutSlice: Equatable, Sendable {
    public let colour: EmployerColour
    public let hours: Double
    public let isWorked: Bool

    public init(colour: EmployerColour, hours: Double, isWorked: Bool) {
        self.colour = colour
        self.hours = hours
        self.isWorked = isWorked
    }

    /// Worked slices first, then rostered ones, each in employer colour order, so the solid part
    /// of the ring is what has already happened.
    public static func slices(for summary: FortnightWorkSummary, employers: [Employer]) -> [DonutSlice] {
        let colourOf = Dictionary(employers.map { ($0.id, $0.colour) }, uniquingKeysWith: { first, _ in first })
        let shares = summary.hoursByEmployer
            .map { (colour: colourOf[$0.employerID] ?? .violet, hours: $0) }
            .sorted { $0.colour.order < $1.colour.order }
        let worked = shares.map { DonutSlice(colour: $0.colour, hours: $0.hours.hoursWorked, isWorked: true) }
        let rostered = shares.map { DonutSlice(colour: $0.colour, hours: $0.hours.hoursRostered, isWorked: false) }
        return (worked + rostered).filter { $0.hours > 0 }
    }
}

/// The fortnight's hours as a ring, with a tick at the 48-hour limit. Past 48 the ring rescales,
/// so the tick moves back and the overflow shows beyond it.
public struct FortnightDonut: View {
    private let slices: [DonutSlice]
    private let lineWidth: CGFloat

    public init(slices: [DonutSlice], lineWidth: CGFloat) {
        self.slices = slices
        self.lineWidth = lineWidth
    }

    public var body: some View {
        Canvas { context, size in
            let total = slices.reduce(0) { $0 + $1.hours }
            let ringHours = max(WorkLimitPolicy.hoursPerFortnight, total)
            let tickOverhang = lineWidth / 4
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - lineWidth / 2 - tickOverhang
            let gap = Angle.radians(2 / radius)

            func arc(from start: Double, to end: Double) -> Path {
                Path { path in
                    path.addArc(center: centre, radius: radius,
                                startAngle: .degrees(start / ringHours * 360 - 90),
                                endAngle: .degrees(end / ringHours * 360 - 90) - gap,
                                clockwise: false)
                }
            }

            context.stroke(arc(from: 0, to: ringHours), with: .color(Palette.track), lineWidth: lineWidth)
            var hoursSoFar = 0.0
            for slice in slices {
                context.stroke(
                    arc(from: hoursSoFar, to: hoursSoFar + slice.hours),
                    with: .color(slice.colour.color.opacity(slice.isWorked ? 1 : 0.42)),
                    lineWidth: lineWidth
                )
                hoursSoFar += slice.hours
            }

            let tickAngle = Angle.degrees(WorkLimitPolicy.hoursPerFortnight / ringHours * 360 - 90)
            let inner = radius - lineWidth / 2 - tickOverhang
            let outer = radius + lineWidth / 2 + tickOverhang
            var tick = Path()
            tick.move(to: CGPoint(x: centre.x + inner * cos(tickAngle.radians), y: centre.y + inner * sin(tickAngle.radians)))
            tick.addLine(to: CGPoint(x: centre.x + outer * cos(tickAngle.radians), y: centre.y + outer * sin(tickAngle.radians)))
            context.stroke(tick, with: .color(Palette.ink), style: StrokeStyle(lineWidth: max(2, lineWidth / 7), lineCap: .round))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
