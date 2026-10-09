/// Shared normalized oblique projection for both board renderers. No Apple framework dependency.
public struct BoardProjection: Sendable {
    public let size: Int
    public init(size: Int) { precondition(size > 1); self.size = size }
    public func center(_ point: Point) -> (x: Double, y: Double) {
        let row = Double(point.y) / Double(size - 1)
        let width = 0.74 + 0.12 * row
        return (0.5 + (Double(point.x) / Double(size - 1) - 0.5) * width, 0.18 + 0.65 * row)
    }
    /// Partition targets by row/column; tapping a sprite's head never changes which cell is selected.
    public func hit(x: Double, y: Double) -> Point? {
        let row = (y - 0.18) / 0.65
        let halfStep = 0.5 / Double(size - 1)
        guard row >= -halfStep && row <= 1 + halfStep else { return nil }
        let ry = min(size - 1, max(0, Int((row * Double(size - 1)).rounded())))
        let width = 0.74 + 0.12 * Double(ry) / Double(size - 1)
        let column = (x - 0.5) / width + 0.5
        guard column >= -halfStep && column <= 1 + halfStep else { return nil }
        return Point(min(size - 1, max(0, Int((column * Double(size - 1)).rounded()))), ry)
    }
}
