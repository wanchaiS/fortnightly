/// Tells surfaces outside the app (the shift status widget) that shifts changed.
public protocol ShiftDisplayRefreshing: Sendable {
    func shiftsDidChange()
}
