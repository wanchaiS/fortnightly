import Combine
import FortnightlyKit
import SwiftUI

/// Home screen: how close each fortnight containing today is to 48 hours, and what to do now.
struct FortnightBoardView: View {
    enum Sheet: Identifiable {
        case roster(day: Date?)
        case day(WorkDay)
        case shift(ShiftListing)
        case times(ShiftTimesSheet.Purpose)

        var id: String {
            switch self {
            case let .roster(day): "roster-\(day?.description ?? "")"
            case let .day(day): "day-\(day.date)"
            case let .shift(listing): "shift-\(listing.id)"
            case let .times(purpose): "times-\(purpose.id)"
            }
        }
    }

    @State private var model: FortnightBoardModel
    @State private var sheet: Sheet?
    @State private var showsLargeDonut = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var appearance

    init(services: FortnightlyServices) {
        _model = State(initialValue: FortnightBoardModel(services: services))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let fortnight = model.selected {
                    VStack(spacing: 12) {
                        donutSection(fortnight)
                            .onGeometryChange(for: Bool.self) { $0.frame(in: .scrollView).maxY > 24 } action: { visible in
                                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { showsLargeDonut = visible }
                            }
                        if let missed = model.missedShifts.first, !dockShowsMissedShift {
                            answerRow(missed)
                        }
                        if !fortnight.hasShifts {
                            Text("No shifts in this fortnight yet. Add each shift when your manager sends the roster, and Fortnightly will remind you to clock in.")
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if typeSize.isAccessibilitySize {
                            dayList(fortnight)
                        } else {
                            dayRows(fortnight)
                        }
                    }
                    .padding(16)
                }
            }
            .background(Palette.ground)
            .safeAreaInset(edge: .top, spacing: 0) { shellHeader }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                DockView(
                    currentShift: model.currentShift,
                    fortnightOverLimit: model.fortnightOverLimit,
                    actions: model.actions,
                    enterTimes: { sheet = .times(.enterMissedTimes($0)) },
                    rosterShift: { sheet = .roster(day: nil) }
                )
                .problemAlert(Bindable(model.actions).problem)
            }
            .navyNavigationBar(title: "Fortnight", showsTitle: !showsLargeDonut)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Jobs") { JobsView(services: model.services) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { sheet = .roster(day: nil) } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Roster a shift")
                }
            }
        }
        .tint(Palette.tint)
        .sheet(item: $sheet, onDismiss: model.refresh) { sheet in
            sheetContent(sheet)
        }
        .problemAlert($model.problem)
        .onAppear {
            model.refresh()
            model.refreshReminders()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.refresh()
                model.refreshReminders()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: FortnightlyServices.recordsChangedElsewhere).receive(on: RunLoop.main)) { _ in model.refresh() }
        // A rostered start or finish passing changes what the dock asks.
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in model.refresh() }
    }

    // MARK: Shell

    private var shellHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsLargeDonut {
                Text("Fortnight")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
            }
            Picker("Work fortnight", selection: $model.selectedIndex) {
                ForEach(Array(model.fortnights.enumerated()), id: \.offset) { index, fortnight in
                    Text("From \(fortnight.summary.fortnight.startsOn.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
                        .tag(index)
                }
            }
            .pickerStyle(.segmented)
            if !showsLargeDonut, let fortnight = model.selected {
                compactSummary(fortnight)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(Palette.shell(for: appearance))
        .environment(\.colorScheme, .dark)
    }

    private func compactSummary(_ fortnight: FortnightBoardModel.Fortnight) -> some View {
        HStack(spacing: 10) {
            FortnightDonut(slices: DonutSlice.slices(for: fortnight.summary, employers: model.employers), lineWidth: 7)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(fortnight.summary.hoursTowardLimit.hoursDescription) of \(WorkLimitPolicy.hoursPerFortnight.hoursDescription) h")
                    .font(.headline)
                    .monospacedDigit()
                Text(hoursLeftLine(fortnight.summary))
                    .font(.footnote)
                    .foregroundStyle(fortnight.summary.status.color)
            }
            .foregroundStyle(.white)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Donut

    private func donutSection(_ fortnight: FortnightBoardModel.Fortnight) -> some View {
        let summary = fortnight.summary
        return VStack(spacing: 8) {
            ZStack {
                FortnightDonut(slices: DonutSlice.slices(for: summary, employers: model.employers), lineWidth: 22)
                    .frame(width: 200, height: 200)
                VStack(spacing: 0) {
                    Text(summary.hoursTowardLimit.hoursDescription)
                        .font(.largeTitle.bold())
                        .monospacedDigit()
                    Text("of \(WorkLimitPolicy.hoursPerFortnight.hoursDescription) hours")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 120)
                .foregroundStyle(Palette.ink)
            }
            Text(hoursLeftLine(summary))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(summary.status.color)
            employerKey(summary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.fortnight.datesDescription): \(summary.hoursTowardLimit.hoursDescription) of 48 hours, \(summary.hoursWorked.hoursDescription) worked. \(hoursLeftLine(summary)).")
    }

    private func hoursLeftLine(_ summary: FortnightWorkSummary) -> String {
        let left = WorkLimitPolicy.hoursPerFortnight - summary.hoursTowardLimit
        return switch summary.status {
        case .overLimit: "\((-left).hoursDescription) h over the limit"
        case .approachingLimit: left > 0 ? "\(left.hoursDescription) h left before the limit" : "No hours left before the limit"
        case .withinLimit: "\(left.hoursDescription) h left"
        }
    }

    @ViewBuilder private func employerKey(_ summary: FortnightWorkSummary) -> some View {
        let entries = summary.hoursByEmployer.compactMap { hours in
            model.employers.first { $0.id == hours.employerID }.map { (employer: $0, hours: hours.hoursWorked + hours.hoursRostered) }
        }.sorted { $0.employer.colour.order < $1.employer.colour.order }
        let items = ForEach(entries, id: \.employer.id) { entry in
            HStack(spacing: 6) {
                Circle().fill(entry.employer.colour.color).frame(width: 10, height: 10)
                Text(entry.employer.name)
                Text("\(entry.hours.hoursDescription) h").fontWeight(.semibold).foregroundStyle(Palette.ink).monospacedDigit()
            }
        }
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) { items }
            VStack(alignment: .leading, spacing: 4) { items }
        }
        .font(.footnote)
        .foregroundStyle(Palette.muted)
    }

    // MARK: Missed shift

    private var dockShowsMissedShift: Bool {
        if case .missed = model.currentShift { return true }
        return false
    }

    private func answerRow(_ missed: ShiftListing) -> some View {
        Button { sheet = .shift(missed) } label: {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, WorkLimitStatus.approachingLimit.color)
                Text("\(Text("\(missed.employerName), \(missed.shift.rosteredStart.dayText)").bold()) finished without a clock-in. Did you work it?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.muted)
            }
            .font(.subheadline)
            .foregroundStyle(Palette.ink)
            .padding(12)
            .background(Palette.card, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: Days

    private func dayRows(_ fortnight: FortnightBoardModel.Fortnight) -> some View {
        VStack(spacing: 0) {
            ForEach([0, 7], id: \.self) { firstDay in
                let week = Array(fortnight.days[firstDay ..< firstDay + 7])
                HStack {
                    Text(weekTitle(week))
                    Spacer()
                    Text("\(week.reduce(0) { $0 + $1.hours }.hoursDescription) h").monospacedDigit()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.muted)
                .padding(.top, 10)
                .padding(.bottom, 4)
                ForEach(week) { day in
                    Divider()
                    Button { sheet = .day(day) } label: {
                        DayRow(
                            date: day.date,
                            segments: day.shifts.map { DayBarSegment(listing: $0, now: model.now) },
                            hours: day.hours,
                            isToday: Calendar.current.isDateInToday(day.date),
                            needsAnswer: day.shifts.contains(where: isMissed)
                        )
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .background(Palette.card, in: .rect(cornerRadius: 14))
    }

    /// At the largest text sizes the bars give way to a plain list of the days that have shifts.
    private func dayList(_ fortnight: FortnightBoardModel.Fortnight) -> some View {
        VStack(spacing: 0) {
            ForEach(fortnight.days.filter { !$0.shifts.isEmpty }.reversed()) { day in
                Button { sheet = .day(day) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Calendar.current.isDateInToday(day.date) ? "\(day.date.dayText) · today" : day.date.dayText)
                                .font(.headline)
                            Text(day.shifts.map { shiftSummary($0) }.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Text(day.hours.hoursDescription).monospacedDigit()
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(.vertical, 10)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
        .padding(.horizontal, 14)
        .background(Palette.card, in: .rect(cornerRadius: 14))
    }

    private func shiftSummary(_ listing: ShiftListing) -> String {
        if isMissed(listing) { return "\(listing.employerName) · not clocked in" }
        if listing.shift.status == .notWorked { return "\(listing.employerName) · not working" }
        return "\(listing.employerName) \(listing.shift.rosteredTimesText)"
    }

    private func isMissed(_ listing: ShiftListing) -> Bool {
        listing.shift.status == .rostered && listing.shift.rosteredFinish <= model.now
    }

    /// "Mon 12 – Sun 18 Oct", or "Mon 26 Oct – Sun 1 Nov" across two months.
    private func weekTitle(_ week: [WorkDay]) -> String {
        guard let first = week.first?.date, let last = week.last?.date else { return "" }
        let sameMonth = Calendar.current.isDate(first, equalTo: last, toGranularity: .month)
        let firstStyle: Date.FormatStyle = sameMonth ? .dateTime.weekday(.abbreviated).day() : .dateTime.weekday(.abbreviated).day().month(.abbreviated)
        return "\(first.formatted(firstStyle)) – \(last.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))"
    }

    // MARK: Sheets

    @ViewBuilder private func sheetContent(_ sheet: Sheet) -> some View {
        let done = { self.sheet = nil }
        switch sheet {
        case let .roster(day):
            RosterShiftSheet(services: model.services, day: day, onDone: done)
        case let .day(day):
            DaySheet(day: day, services: model.services, now: model.now, onDone: done)
        case let .shift(listing):
            NavigationStack {
                ShiftDetailsView(listing: listing, services: model.services, now: model.now, onDone: done)
            }
        case let .times(purpose):
            ShiftTimesSheet(purpose: purpose, services: model.services, onDone: done)
        }
    }
}
