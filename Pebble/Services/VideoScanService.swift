import Foundation
import Photos

class VideoScanService {
    static let shared = VideoScanService()

    func findLargeVideos(progress: @escaping (Double) -> Void) async -> [VideoItem] {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)

                let results = PHAsset.fetchAssets(with: fetchOptions)
                var items: [VideoItem] = []
                items.reserveCapacity(results.count)
                let totalCount = results.count

                results.enumerateObjects { asset, index, _ in
                    var item = VideoItem(asset: asset)

                    let resources = PHAssetResource.assetResources(for: asset)
                    if let videoResource = resources.first(where: { $0.type == .video }) ?? resources.first {
                        if let fileSize = videoResource.value(forKey: "fileSize") as? Int64 {
                            item.fileSize = fileSize
                        }
                    }

                    items.append(item)

                    let currentProgress = Double(index + 1) / Double(max(totalCount, 1))
                    progress(min(currentProgress, 1.0))
                }

                items.sort()

                progress(1.0)
                continuation.resume(returning: items)
            }
        }
    }

    func totalVideoSize() async -> Int64 {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)

                let results = PHAsset.fetchAssets(with: fetchOptions)
                var total: Int64 = 0

                results.enumerateObjects { asset, _, _ in
                    let resources = PHAssetResource.assetResources(for: asset)
                    if let resource = resources.first(where: { $0.type == .video }) ?? resources.first {
                        if let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                            total += fileSize
                        }
                    }
                }

                continuation.resume(returning: total)
            }
        }
    }
}
