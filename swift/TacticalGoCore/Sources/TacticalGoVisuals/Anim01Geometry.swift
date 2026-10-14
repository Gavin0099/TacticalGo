/// Candidate geometry fits the original 1024×1152 board canvas. It does not
/// alter the shared normalized game projection or its hit policy.
public struct Anim01Geometry: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public let pitch: Double
    public init(width availableWidth: Double, height availableHeight: Double, boardSize: Int, focusedNine: Bool = false, focusedPhone: Bool = false) {
        // A phone viewport trims the picture's outer margin, not the playable grid.
        // Keep room for upright figures and complete hit cells at all four corners.
        let focused = (focusedNine || focusedPhone) && boardSize == 9
        let seven = focusedPhone && boardSize == 7
        let scale = min(availableWidth / (1024 * (focused ? 0.97 : 1)), availableHeight / (1152 * (focused ? 0.82 : seven ? 0.90 : 1)))
        width = 1024 * scale; height = 1152 * scale
        x = (availableWidth - width) / 2
        y = focused || seven ? availableHeight / 2 - height * 0.505 : (availableHeight - height) / 2
        pitch = min(width * 0.74, height * 0.65) / Double(boardSize - 1)
    }
    public func contains(x px: Double, y py: Double) -> Bool {
        px >= x && px <= x + width && py >= y && py <= y + height
    }
}
