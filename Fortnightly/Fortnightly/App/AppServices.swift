import FortnightlyKit

enum AppServices {
    /// Opened once per process: two Core Data stacks on the same file would conflict.
    static let shared = Result { try FortnightlyServices.appGroup() }
}
