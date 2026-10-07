import FortnightlyKit
import SwiftUI

/// Add a shift the manager has given, or change one, seeing its effect on both fortnights before saving.
struct RosterShiftSheet: View {
    @State private var model: RosterShiftModel
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    init(services: FortnightlyServices, day: Date? = nil, editing: ShiftListing? = nil, onDone: @escaping () -> Void) {
        _model = State(initialValue: RosterShiftModel(services: services, day: day, editing: editing))
        self.onDone = onDone
    }

    var body: some View {
        NavigationStack {
            Form {
                if model.employers.isEmpty {
                    Section {
                        Text("Add the places you work in Jobs first, then roster your shifts there.")
                    }
                } else {
                    employerSection
                    whenSection
                    Section("On that day") {
                        DayRow(date: model.day, segments: model.previewSegments, hours: model.previewSegments.reduce(0) { $0 + $1.hours })
                    }
                    effectsSection
                    warningSection
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.ground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmTitle) {
                        if model.save() { onDone() }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(model.breach == nil ? Palette.tint : WorkLimitStatus.overLimit.color)
                    .disabled(!model.canSave)
                }
            }
        }
        .tint(Palette.tint)
        .onAppear(perform: model.load)
        .onChange(of: model.employerID) { model.updatePreview() }
        .onChange(of: model.day) { model.updatePreview() }
        .onChange(of: model.startTime) { model.updatePreview() }
        .onChange(of: model.finishTime) { model.updatePreview() }
        .problemAlert($model.saveProblem)
    }

    private var employerSection: some View {
        Section("Employer") {
            let picker = Picker("Employer", selection: $model.employerID) {
                ForEach(model.employers) { employer in
                    Text(employer.name).tag(Optional(employer.id))
                }
            }
            .labelsHidden()
            if model.employers.count <= 3 {
                picker.pickerStyle(.segmented)
            } else {
                picker.pickerStyle(.menu)
            }
        }
    }

    private var whenSection: some View {
        Section("When") {
            DatePicker("Day", selection: $model.day, displayedComponents: .date)
            DatePicker("Starts", selection: $model.startTime, displayedComponents: .hourAndMinute)
            DatePicker("Finishes", selection: $model.finishTime, displayedComponents: .hourAndMinute)
        }
    }

    @ViewBuilder private var effectsSection: some View {
        if !model.effects.isEmpty {
            Section("Effect on your work fortnights") {
                ForEach(model.effects, id: \.fortnight.startsOn) { effect in
                    EffectRow(effect: effect)
                }
            }
        }
    }

    @ViewBuilder private var warningSection: some View {
        if let problem = model.ruleProblem ?? breachWarning {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(problem.title).font(.subheadline.weight(.semibold))
                    Text(problem.message).font(.subheadline)
                }
                .foregroundStyle(Palette.ink)
                .listRowBackground(WorkLimitStatus.overLimit.color.opacity(0.12))
            }
        }
    }

    private var title: String {
        guard let editing = model.editing else { return "Roster a shift" }
        return editing.shift.status == .notWorked ? "Put back on my roster" : "Change times"
    }

    private var confirmTitle: String {
        let verb = model.editing == nil ? "Add" : "Save"
        return model.breach == nil ? verb : "\(verb) anyway"
    }

    /// The breach in the use case's own words, without saving anything.
    private var breachWarning: ProblemMessage? {
        guard let breach = model.breach else { return nil }
        return ProblemMessage(RosterShiftError.wouldBreachWorkLimit(fortnight: breach.fortnight, projectedHours: breach.after.hoursTowardLimit))
    }
}

/// "Mon 12 Oct – Sun 25 Oct    46.25 → 50.25 of 48"
private struct EffectRow: View {
    let effect: FortnightEffect

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(effect.after.status.color).frame(width: 8, height: 8)
            Text(effect.fortnight.datesDescription)
            Spacer()
            Text("\(effect.before.hoursTowardLimit.hoursDescription) → \(Text(effect.after.hoursTowardLimit.hoursDescription).bold().foregroundStyle(effect.after.status == .overLimit ? effect.after.status.color : Palette.ink)) of \(WorkLimitPolicy.hoursPerFortnight.hoursDescription)")
                .monospacedDigit()
        }
        .font(.subheadline)
        .foregroundStyle(Palette.ink)
        .accessibilityElement(children: .combine)
    }
}
