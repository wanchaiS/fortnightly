import WidgetKit

public struct WidgetDisplayRefresher: ShiftDisplayRefreshing {
    public init() {}

    public func shiftsDidChange() {
        WidgetCenter.shared.reloadTimelines(ofKind: ShiftStatusWidgetKind.identifier)
    }
}
