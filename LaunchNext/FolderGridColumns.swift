import Foundation

/// Fixed folder columns shared by both renderers and preference loading.
nonisolated enum FolderGridColumns {
    static let defaultValue = 6
    static let range = 3...8

    static func normalized(_ value: Int?) -> Int {
        min(range.upperBound, max(range.lowerBound, value ?? defaultValue))
    }

    static func maximumIconSize(width: CGFloat, columns: Int) -> CGFloat {
        let count = CGFloat(normalized(columns))
        let cellWidth = (max(1, width - 24) - 22 * (count - 1)) / count
        return max(1, cellWidth - 4)
    }
}
