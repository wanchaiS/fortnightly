import FortnightlyKit
import SwiftUI
import UserNotifications

/// Three steps before the board: the rule, the prompts, the first employer.
struct OnboardingView: View {
    let services: FortnightlyServices
    let onFinish: () -> Void
    @State private var step = 1
    @State private var employerName = ""
    @State private var payCycle: PayCycle = .fortnightly
    @State private var problem: ProblemMessage?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch step {
            case 1: ruleStep
            case 2: promptsStep
            default: employerStep
            }
            HStack(spacing: 6) {
                ForEach(1 ... 3, id: \.self) { dot in
                    Circle().fill(dot == step ? Palette.ink : Palette.track).frame(width: 7, height: 7)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(step) of 3")
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .foregroundStyle(Palette.ink)
        .background(Palette.ground)
        .tint(Palette.tint)
        .problemAlert($problem)
    }

    // MARK: Steps

    private var ruleStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            heading("48 hours in any fortnight",
                    "Your student visa limits work to 48 hours in any 14 days that start on a Monday. Every week belongs to two of them, and both count.")
            ThreeWeeksIllustration()
            Text("Fortnightly adds up your hours across all your jobs and warns you before a shift would take either fortnight over.")
                .foregroundStyle(Palette.muted)
            Spacer(minLength: 0)
            primaryButton("Continue") { step = 2 }
        }
    }

    private var promptsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            heading("A prompt at every start and finish",
                    "When a shift starts or ends, Fortnightly asks you to clock in or out, so your record has the times you actually worked. Nothing leaves your phone.")
            PromptPreview()
            Spacer(minLength: 0)
            primaryButton("Turn on notifications") {
                Task {
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                    step = 3
                }
            }
            secondaryButton("Not now") { step = 3 }
        }
    }

    private var employerStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            heading("Where do you work?", "Add your first employer. You can add more, and course breaks, in Jobs.")
            VStack(spacing: 0) {
                TextField("Name, like Café Roma", text: $employerName)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                Divider()
                HStack {
                    Text("Paid")
                    Spacer()
                    Picker("Paid", selection: $payCycle) {
                        ForEach(PayCycle.allCases, id: \.self) { cycle in
                            Text(cycle.rawValue.capitalized).tag(cycle)
                        }
                    }
                    .labelsHidden()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }
            .background(Palette.card, in: .rect(cornerRadius: 12))
            Spacer(minLength: 0)
            primaryButton("Add and start") {
                do {
                    try services.addEmployer.execute(EmployerDetails(name: employerName, payCycle: payCycle, payCycleStartsOn: .now))
                    onFinish()
                } catch {
                    problem = ProblemMessage(error)
                }
            }
            secondaryButton("I'll add it later", action: onFinish)
        }
    }

    // MARK: Parts

    private func heading(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
            Text(text)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 20)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 52)
        }
        .foregroundStyle(Palette.card)
        .background(Palette.ink, in: .rect(cornerRadius: 14))
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 52)
        }
        .foregroundStyle(Palette.ink)
        .background(Palette.track, in: .rect(cornerRadius: 14))
    }
}

/// The Home Affairs example: weeks 1 and 2 are within the limit, weeks 2 and 3 are not.
private struct ThreeWeeksIllustration: View {
    @ScaledMetric(relativeTo: .subheadline) private var rowHeight = 40

    private let weeks: [(name: String, shifts: [EmployerColour])] = [
        ("Week 1", [.violet, .teal, .violet]),
        ("Week 2", [.violet, .teal, .violet, .teal]),
        ("Week 3", [.teal, .violet, .teal, .violet, .teal]),
    ]

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 6) {
                VStack(spacing: 0) {
                    ForEach(weeks, id: \.name) { week in
                        HStack(spacing: 8) {
                            Text(week.name).fontWeight(.semibold)
                            DayBar(segments: week.shifts.map { DayBarSegment(colour: $0, hours: 6, form: .worked) }, minimumHoursAcross: 36)
                            Text("\(week.shifts.count * 6) h").fontWeight(.semibold).monospacedDigit()
                        }
                        .frame(height: rowHeight)
                    }
                }
                ZStack(alignment: .topLeading) {
                    Bracket().stroke(Palette.ink, lineWidth: 2)
                        .frame(width: 8, height: rowHeight * 1.8)
                        .offset(y: rowHeight * 0.1)
                    Bracket().stroke(WorkLimitStatus.overLimit.color, lineWidth: 2)
                        .frame(width: 8, height: rowHeight * 1.8)
                        .offset(x: 8, y: rowHeight * 1.1)
                }
                .frame(width: 18, height: rowHeight * 3, alignment: .topLeading)
            }
            HStack { Text("Weeks 1 and 2"); Spacer(); Text("42 h").bold() }
            HStack { Text("Weeks 2 and 3"); Spacer(); Text("54 h, over").bold().foregroundStyle(WorkLimitStatus.overLimit.color) }
        }
        .font(.subheadline)
        .monospacedDigit()
        .padding(14)
        .background(Palette.card, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Example: 18 hours in week 1, 24 in week 2, 30 in week 3. Weeks 1 and 2 make 42 hours, within the limit. Weeks 2 and 3 make 54 hours, over the limit.")
    }
}

/// A closing bracket joining two week rows.
private struct Bracket: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
    }
}

/// What the student will see when a shift starts.
private struct PromptPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Palette.actNow)
                    .frame(width: 22, height: 22)
                    .background(Palette.shell, in: .rect(cornerRadius: 6))
                Text("Fortnightly").font(.footnote.weight(.semibold))
                Spacer()
                Text("now").font(.footnote)
            }
            .foregroundStyle(Palette.muted)
            Text("Café Roma shift starting").font(.headline)
            Text("Did you start on time? Clock in so your hours are recorded.")
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
        }
        .padding(14)
        .background(Palette.card, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
    }
}
