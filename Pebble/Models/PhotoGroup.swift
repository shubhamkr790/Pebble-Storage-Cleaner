import Foundation
import Photos

struct PhotoGroup: Identifiable {
    let id = UUID()
    var assets: [PHAsset]
    var bestPickIndex: Int
    var selectedIndices: Set<Int>

    var bestAsset: PHAsset {
        assets[bestPickIndex]
    }

    var selectedAssets: [PHAsset] {
        selectedIndices.compactMap { index in
            guard index < assets.count else { return nil }
            return assets[index]
        }
    }

    var duplicateCount: Int {
        assets.count - 1
    }

    mutating func selectAllExceptBest() {
        selectedIndices = Set(assets.indices.filter { $0 != bestPickIndex })
    }

    mutating func deselectAll() {
        selectedIndices.removeAll()
    }

    mutating func toggleSelection(at index: Int) {
        guard index != bestPickIndex else { return }
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }
}

struct ScreenshotItem: Identifiable {
    let id: String
    let asset: PHAsset
    var isSelected: Bool = false

    var creationDate: Date {
        asset.creationDate ?? .distantPast
    }

    var monthKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: creationDate)
    }

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
    }
}

struct ScreenshotMonthGroup: Identifiable {
    let id: String
    let monthTitle: String
    var items: [ScreenshotItem]

    var allSelected: Bool {
        items.allSatisfy { $0.isSelected }
    }

    var selectedCount: Int {
        items.filter { $0.isSelected }.count
    }
}

struct VideoItem: Identifiable, Comparable {
    let id: String
    let asset: PHAsset
    var fileSize: Int64
    var isSelected: Bool = false

    var duration: TimeInterval {
        asset.duration
    }

    var creationDate: Date {
        asset.creationDate ?? .distantPast
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: creationDate)
    }

    init(asset: PHAsset, fileSize: Int64 = 0) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.fileSize = fileSize
    }

    static func < (lhs: VideoItem, rhs: VideoItem) -> Bool {
        lhs.fileSize > rhs.fileSize
    }
}
