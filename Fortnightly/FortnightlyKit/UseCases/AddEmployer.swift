import Foundation

public struct EmployerDetails: Sendable {
    public var name: String
    public var payCycle: PayCycle
    public var payCycleStartsOn: Date
    /// `nil` adds a new employer.
    public var editing: Employer.ID?

    public init(name: String, payCycle: PayCycle = .fortnightly, payCycleStartsOn: Date, editing: Employer.ID? = nil) {
        self.name = name
        self.payCycle = payCycle
        self.payCycleStartsOn = payCycleStartsOn
        self.editing = editing
    }
}

public enum AddEmployerError: Error, Equatable {
    case nameMissing
    case nameAlreadyUsed(existingName: String)
    case employerNotFound
    case recordsUnavailable
}

extension AddEmployerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .nameMissing:
            "Your employer needs a name."
        case let .nameAlreadyUsed(existingName):
            "You already have \(existingName) in your jobs."
        case .employerNotFound:
            "This employer is no longer in your list."
        case .recordsUnavailable:
            "This employer couldn't be saved."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .nameMissing:
            "Use the name on your payslip, like Café Roma."
        case .nameAlreadyUsed:
            "Roster your shifts there instead. If it's a different place, add a detail to the name, like \"Café Roma Newtown\"."
        case .employerNotFound:
            "Check your employers in Jobs."
        case .recordsUnavailable:
            "Your shifts are safe. Try again."
        }
    }
}

public struct AddEmployer: Sendable {
    private let employers: any EmployerRepository
    private let display: any ShiftDisplayRefreshing

    public init(employers: any EmployerRepository, display: any ShiftDisplayRefreshing) {
        self.employers = employers
        self.display = display
    }

    /// Two current jobs can't share a name: their hours would split across two slices of the donut.
    /// Names match ignoring case, accents and extra spaces, so "cafe roma " is Café Roma.
    @discardableResult
    public func execute(_ details: EmployerDetails) throws(AddEmployerError) -> Employer {
        let name = details.name.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard !name.isEmpty else { throw .nameMissing }
        let currentEmployers = try read { try employers.employers(includingArchived: false) }
        let sameName = currentEmployers.first {
            $0.id != details.editing && $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        if let sameName { throw .nameAlreadyUsed(existingName: sameName.name) }

        var employer: Employer
        if let editedID = details.editing {
            guard let edited = try read({ try employers.employer(withID: editedID) }) else { throw .employerNotFound }
            employer = edited
        } else {
            let takenColours = currentEmployers.map(\.colour)
            // Six colours cover nearly every student; a seventh current job starts again from the first.
            let colour = EmployerColour.allCases.first { !takenColours.contains($0) } ?? .violet
            employer = Employer(name: name, colour: colour, payCycleStartsOn: details.payCycleStartsOn)
        }
        employer.name = name
        employer.payCycle = details.payCycle
        employer.payCycleStartsOn = details.payCycleStartsOn
        try read { try employers.save(employer) }
        display.shiftsDidChange()
        return employer
    }

    private func read<Value>(_ operation: () throws -> Value) throws(AddEmployerError) -> Value {
        do {
            return try operation()
        } catch {
            throw .recordsUnavailable
        }
    }
}
