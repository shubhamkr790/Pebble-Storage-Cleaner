import Foundation

struct StorageInfo {
    let totalCapacity: Int64
    let availableCapacity: Int64

    var usedCapacity: Int64 {
        totalCapacity - availableCapacity
    }

    var usedPercentage: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(usedCapacity) / Double(totalCapacity) * 100
    }

    var freePercentage: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(availableCapacity) / Double(totalCapacity) * 100
    }

    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalCapacity, countStyle: .file)
    }

    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: usedCapacity, countStyle: .file)
    }

    var formattedAvailable: String {
        ByteCountFormatter.string(fromByteCount: availableCapacity, countStyle: .file)
    }

    static let placeholder = StorageInfo(totalCapacity: 128_000_000_000, availableCapacity: 48_000_000_000)
}

struct CategoryScanResult: Identifiable {
    let id = UUID()
    let category: PebbleCategory
    var itemCount: Int
    var freeableBytes: Int64
    var isScanned: Bool = false

    var formattedFreeable: String {
        ByteCountFormatter.string(fromByteCount: freeableBytes, countStyle: .file)
    }

    var subtitle: String {
        guard isScanned else { return "Tap to scan" }
        guard itemCount > 0 else { return "No items found" }

        switch category {
        case .similarPhotos:
            return "\(itemCount) similar items found"
        case .screenshots:
            return "\(itemCount) screenshots found"
        case .largeVideos:
            return "\(itemCount) large videos found"
        case .duplicateContacts:
            return "\(itemCount) duplicates found"
        case .blurryPhotos:
            return "\(itemCount) blurry photos found"
        }
    }
}
