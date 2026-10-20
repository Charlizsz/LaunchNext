import CoreGraphics

nonisolated enum FolderRowSpacing {
    static let defaultValue: Double = 10
    static let range: ClosedRange<Double> = 0...40

    static func normalized(_ value: Double?) -> Double {
        guard let value, value.isFinite else { return defaultValue }
        return min(range.upperBound, max(range.lowerBound, value))
    }
}
