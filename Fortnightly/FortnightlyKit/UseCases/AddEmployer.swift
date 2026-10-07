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
    @discardableResult
    public func execute(_ details: EmployerDetails) throws(AddEmployerError) -> Employer {
        // TDD red: not implemented yet.
        Employer(name: details.name, colour: .violet, payCycle: details.payCycle, payCycleStartsOn: details.payCycleStartsOn)
    }
}
