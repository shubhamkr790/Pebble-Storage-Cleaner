import Foundation
import Photos
import Contacts

enum CleanupItemType: String {
    case similarPhoto = "Similar Photos"
    case screenshot = "Screenshots"
    case largeVideo = "Large Videos"
    case duplicateContact = "Duplicate Contacts"

    var category: PebbleCategory {
        switch self {
        case .similarPhoto: return .similarPhotos
        case .screenshot: return .screenshots
        case .largeVideo: return .largeVideos
        case .duplicateContact: return .duplicateContacts
        }
    }
}

struct CleanupSummaryItem: Identifiable {
    let id = UUID()
    let type: CleanupItemType
    let count: Int
    let estimatedBytes: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: estimatedBytes, countStyle: .file)
    }
}

struct CleanupPlan {
    var photoAssets: [PHAsset] = []
    var screenshotAssets: [PHAsset] = []
    var videoAssets: [PHAsset] = []
    var contactsToDelete: [CNContact] = []
    var contactsToMerge: [(primary: CNContact, duplicates: [CNContact])] = []

    var totalAssets: Int {
        photoAssets.count + screenshotAssets.count + videoAssets.count
    }

    var totalContacts: Int {
        contactsToDelete.count + contactsToMerge.flatMap(\.duplicates).count
    }

    var totalItems: Int {
        totalAssets + totalContacts
    }

    var isEmpty: Bool {
        totalItems == 0
    }

    var summaryItems: [CleanupSummaryItem] {
        var items: [CleanupSummaryItem] = []
        if !photoAssets.isEmpty {
            items.append(CleanupSummaryItem(type: .similarPhoto, count: photoAssets.count, estimatedBytes: 0))
        }
        if !screenshotAssets.isEmpty {
            items.append(CleanupSummaryItem(type: .screenshot, count: screenshotAssets.count, estimatedBytes: 0))
        }
        if !videoAssets.isEmpty {
            items.append(CleanupSummaryItem(type: .largeVideo, count: videoAssets.count, estimatedBytes: 0))
        }
        let contactCount = contactsToDelete.count + contactsToMerge.flatMap(\.duplicates).count
        if contactCount > 0 {
            items.append(CleanupSummaryItem(type: .duplicateContact, count: contactCount, estimatedBytes: 0))
        }
        return items
    }
}

struct CleanupResult {
    let success: Bool
    let freedBytes: Int64
    let deletedPhotoCount: Int
    let deletedVideoCount: Int
    let deletedContactCount: Int
    let mergedContactCount: Int
    let error: Error?

    var totalDeletedItems: Int {
        deletedPhotoCount + deletedVideoCount + deletedContactCount + mergedContactCount
    }

    var formattedFreed: String {
        ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
    }

    static let empty = CleanupResult(
        success: true,
        freedBytes: 0,
        deletedPhotoCount: 0,
        deletedVideoCount: 0,
        deletedContactCount: 0,
        mergedContactCount: 0,
        error: nil
    )
}
