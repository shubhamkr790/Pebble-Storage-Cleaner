import Foundation
import Photos
import UIKit

class CleanupService {
    static let shared = CleanupService()
    private let contactService = ContactScanService.shared

    func executeCleanup(_ plan: CleanupPlan) async -> CleanupResult {
        var freedBytes: Int64 = 0
        var deletedPhotoCount = 0
        var deletedVideoCount = 0
        var deletedContactCount = 0
        var mergedContactCount = 0
        var lastError: Error?

        let allPhotoAssets = plan.photoAssets + plan.screenshotAssets
        if !allPhotoAssets.isEmpty {
            do {
                freedBytes += await PhotoScanService.shared.estimateSize(of: allPhotoAssets)

                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.deleteAssets(allPhotoAssets as NSFastEnumeration)
                }
                deletedPhotoCount = allPhotoAssets.count

                await MainActor.run {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                lastError = error
                print("CleanupService photo deletion error: \(error)")
            }
        }

        if !plan.videoAssets.isEmpty {
            do {
                for asset in plan.videoAssets {
                    let resources = PHAssetResource.assetResources(for: asset)
                    if let resource = resources.first,
                       let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                        freedBytes += fileSize
                    }
                }

                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.deleteAssets(plan.videoAssets as NSFastEnumeration)
                }
                deletedVideoCount = plan.videoAssets.count
            } catch {
                lastError = error
                print("CleanupService video deletion error: \(error)")
            }
        }

        for merge in plan.contactsToMerge {
            do {
                try await contactService.mergeContacts(primary: merge.primary, duplicates: merge.duplicates)
                mergedContactCount += merge.duplicates.count
            } catch {
                lastError = error
                print("CleanupService contact merge error: \(error)")
            }
        }

        if !plan.contactsToDelete.isEmpty {
            do {
                try await contactService.deleteContacts(plan.contactsToDelete)
                deletedContactCount = plan.contactsToDelete.count
            } catch {
                lastError = error
                print("CleanupService contact deletion error: \(error)")
            }
        }

        await MainActor.run {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        return CleanupResult(
            success: lastError == nil,
            freedBytes: freedBytes,
            deletedPhotoCount: deletedPhotoCount,
            deletedVideoCount: deletedVideoCount,
            deletedContactCount: deletedContactCount,
            mergedContactCount: mergedContactCount,
            error: lastError
        )
    }
}
