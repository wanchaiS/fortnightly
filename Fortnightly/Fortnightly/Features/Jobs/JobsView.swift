import FortnightlyKit
import SwiftUI

/// Where the student works, and when their course isn't in session.
struct JobsView: View {
    @State private var model: JobsModel
    @State private var addingEmployer = false
    @State private var editingBreak: CourseBreak?
    @State private var addingBreak = false

    init(services: FortnightlyServices) {
        _model = State(initialValue: JobsModel(services: services))
    }

    var body: some View {
        List {
            Section("Where you work") {
                ForEach(model.employers) { employer in
                    NavigationLink {
                        EmployerForm(model: model, editing: employer)
                    } label: {
                        HStack(spacing: 10) {
                            Circle().fill(employer.colour.color).frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(employer.name).foregroundStyle(Palette.ink)
                                Text("Paid \(employer.payCycle.rawValue)").font(.subheadline).foregroundStyle(Palette.muted)
                            }
                        }
                    }
                }
                Button("Add an employer", systemImage: "plus") { addingEmployer = true }
            }

            Section {
                ForEach(model.courseBreaks) { courseBreak in
                    Button { editingBreak = courseBreak } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(courseBreak.name).foregroundStyle(Palette.ink)
                            Text(courseBreak.datesDescription).font(.subheadline).foregroundStyle(Palette.muted)
                        }
                    }
                    .swipeActions {
                        Button("Remove", role: .destructive) { model.remove(courseBreak) }
                    }
                }
                Button("Add a course break", systemImage: "plus") { addingBreak = true }
            } header: {
                Text("Course breaks")
            } footer: {
                Text("The 48-hour limit doesn't apply while your course isn't in session.")
            }

            if !model.archivedEmployers.isEmpty {
                Section {
                    ForEach(model.archivedEmployers) { employer in
                        Text(employer.name).foregroundStyle(Palette.muted)
                    }
                } header: {
                    Text("Archived")
                } footer: {
                    Text("Hours you worked at archived employers still count.")
                }
            }

            Section {
                #if DEBUG
                Button("Load sample shifts (testing only)") { model.loadSampleRoster() }
                #endif
            } footer: {
                Text("Fortnightly helps you track your hours. It isn't legal advice: check your own visa conditions in VEVO.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.ground)
        .navyNavigationBar(title: "Jobs")
        .onAppear(perform: model.load)
        .sheet(isPresented: $addingEmployer, onDismiss: model.load) {
            NavigationStack { EmployerForm(model: model, editing: nil) }
        }
        .sheet(isPresented: $addingBreak, onDismiss: model.load) {
            CourseBreakForm(model: model, editing: nil)
        }
        .sheet(item: $editingBreak, onDismiss: model.load) { courseBreak in
            CourseBreakForm(model: model, editing: courseBreak)
        }
        .problemAlert($model.problem)
    }
}

struct EmployerForm: View {
    let model: JobsModel
    let editing: Employer?
    @State private var name: String
    @State private var payCycle: PayCycle
    @State private var payCycleStartsOn: Date
    @State private var problem: ProblemMessage?
    @Environment(\.dismiss) private var dismiss

    init(model: JobsModel, editing: Employer?) {
        self.model = model
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _payCycle = State(initialValue: editing?.payCycle ?? .fortnightly)
        _payCycleStartsOn = State(initialValue: editing?.payCycleStartsOn ?? .now)
    }

    var body: some View {
        Form {
            Section {
                TextField("Name, like Café Roma", text: $name)
                    .textInputAutocapitalization(.words)
            }
            Section {
                Picker("Paid", selection: $payCycle) {
                    ForEach(PayCycle.allCases, id: \.self) { cycle in
                        Text(cycle.rawValue.capitalized).tag(cycle)
                    }
                }
                DatePicker("A pay period starts", selection: $payCycleStartsOn, displayedComponents: .date)
            } header: {
                Text("Pay")
            } footer: {
                Text("From your payslip, so you can compare your hours with each pay period.")
            }
            if let editing {
                Section {
                    Button("Archive \(editing.name)", role: .destructive) {
                        attempt { try model.archive(editing) }
                    }
                } footer: {
                    Text("Archived employers leave your lists. Hours you worked there keep counting.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.ground)
        .navigationTitle(editing == nil ? "Add an employer" : editing!.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if editing == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    attempt { try model.saveEmployer(EmployerDetails(name: name, payCycle: payCycle, payCycleStartsOn: payCycleStartsOn, editing: editing?.id)) }
                }
                .fontWeight(.semibold)
            }
        }
        .problemAlert($problem)
    }

    private func attempt(_ change: () throws -> Void) {
        do {
            try change()
            dismiss()
        } catch {
            problem = ProblemMessage(error)
        }
    }
}

struct CourseBreakForm: View {
    let model: JobsModel
    let editing: CourseBreak?
    @State private var name: String
    @State private var startsOn: Date
    @State private var endsOn: Date
    @State private var problem: ProblemMessage?
    @Environment(\.dismiss) private var dismiss

    init(model: JobsModel, editing: CourseBreak?) {
        self.model = model
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _startsOn = State(initialValue: editing?.startsOn ?? .now)
        _endsOn = State(initialValue: editing?.endsOn ?? Calendar.current.date(byAdding: .day, value: 6, to: .now)!)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name, like Summer break", text: $name)
                }
                Section {
                    DatePicker("First day", selection: $startsOn, displayedComponents: .date)
                    DatePicker("Last day", selection: $endsOn, displayedComponents: .date)
                } footer: {
                    Text("Check your university's academic calendar for the exact dates.")
                }
                if let editing {
                    Section {
                        Button("Remove this break", role: .destructive) {
                            model.remove(editing)
                            dismiss()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.ground)
            .navigationTitle(editing == nil ? "Add a course break" : "Course break")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try model.saveCourseBreak(CourseBreakDetails(name: name, startsOn: startsOn, endsOn: endsOn, editing: editing?.id))
                            dismiss()
                        } catch {
                            problem = ProblemMessage(error)
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .tint(Palette.tint)
        .problemAlert($problem)
    }
}
