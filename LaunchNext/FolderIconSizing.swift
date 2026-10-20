import CoreGraphics

nonisolated enum FolderIconSizing {
    static let defaultValue: Double = 80
    static let range: ClosedRange<Double> = 40...128

    static func normalized(_ value: Double?) -> Double {
        guard let value, value.isFinite else { return defaultValue }
        return min(range.upperBound, max(range.lowerBound, value))
    }
}
