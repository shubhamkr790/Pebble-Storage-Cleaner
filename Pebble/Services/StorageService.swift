import Foundation

class StorageService {
    static let shared = StorageService()

    func getStorageInfo() -> StorageInfo {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let values = try fileURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let available = values.volumeAvailableCapacityForImportantUsage ?? 0
            return StorageInfo(totalCapacity: total, availableCapacity: available)
        } catch {
            print("StorageService error: \(error)")
            return StorageInfo.placeholder
        }
    }

    func estimatePhotoLibrarySize() async -> Int64 {
        return 0
    }
}
