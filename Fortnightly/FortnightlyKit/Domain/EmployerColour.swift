/// Given in order of adding. None is the "act now" yellow or a work-limit green, orange or red,
/// so a job never looks like a warning.
public enum EmployerColour: String, CaseIterable, Sendable {
    case violet
    case teal
    case magenta
    case cobalt
    case bronze
    case moss

    public var order: Int { Self.allCases.firstIndex(of: self)! }
}
