/// Phone match slots depend only on the container, never on battle/UI state.
public struct PhoneMatchLayout: Equatable, Sendable {
    public let width: Double, boardHeight: Double
    public static let headerHeight = 40.0
    public static let resourcesHeight = 48.0
    public static let statusHeight = 20.0
    public static let controlsHeight = 200.0
    public static let spacing = 4.0
    public static let verticalPadding = 4.0
    public init(width: Double, height: Double) {
        let w = width.isFinite ? max(0,width-12):0
        let h = height.isFinite ? max(0,height):0
        self.width = w
        let reserved = Self.headerHeight + Self.resourcesHeight + Self.statusHeight + Self.controlsHeight
            + Self.spacing*4 + Self.verticalPadding*2
        boardHeight = max(0,min(w*1.04,h-reserved))
    }
}
