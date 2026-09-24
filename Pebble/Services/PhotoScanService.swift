import Foundation
import Photos
import UIKit
import Accelerate

class PhotoScanService {
    static let shared = PhotoScanService()
    private let imageManager = PHCachingImageManager()

    private let hashSize = 8
    private let similarityThreshold = 10

    func findSimilarPhotos(progress: @escaping (Double) -> Void) async -> [PhotoGroup] {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

                let allAssets = PHAsset.fetchAssets(with: fetchOptions)
                let totalCount = allAssets.count
                guard totalCount > 1 else {
                    continuation.resume(returning: [])
                    return
                }

                var assetArray: [PHAsset] = []
                assetArray.reserveCapacity(totalCount)
                allAssets.enumerateObjects { asset, _, _ in
                    if !asset.mediaSubtypes.contains(.photoScreenshot) {
                        assetArray.append(asset)
                    }
                }

                guard assetArray.count > 1 else {
                    continuation.resume(returning: [])
                    return
                }

                let metadataGroups = self.metadataPass(assets: assetArray) { p in
                    progress(p * 0.3)
                }

                var groupedIds = Set<String>()
                for group in metadataGroups {
                    for asset in group {
                        groupedIds.insert(asset.localIdentifier)
                    }
                }

                let ungroupedAssets = assetArray.filter { !groupedIds.contains($0.localIdentifier) }
                let phashGroups = await self.perceptualHashPass(assets: ungroupedAssets) { p in
                    progress(0.3 + p * 0.7)
                }

                var allGroups: [PhotoGroup] = []

                for cluster in metadataGroups {
                    if cluster.count >= 2 {
                        let bestIdx = self.findBestPhoto(in: cluster)
                        var group = PhotoGroup(assets: cluster, bestPickIndex: bestIdx, selectedIndices: [])
                        group.selectAllExceptBest()
                        allGroups.append(group)
                    }
                }

                for cluster in phashGroups {
                    if cluster.count >= 2 {
                        let bestIdx = self.findBestPhoto(in: cluster)
                        var group = PhotoGroup(assets: cluster, bestPickIndex: bestIdx, selectedIndices: [])
                        group.selectAllExceptBest()
                        allGroups.append(group)
                    }
                }

                progress(1.0)
                continuation.resume(returning: allGroups)
            }
        }
    }

    private func metadataPass(assets: [PHAsset], progress: @escaping (Double) -> Void) -> [[PHAsset]] {
        var groups: [[PHAsset]] = []
        var processed = Set<Int>()

        for i in 0..<assets.count {
            if processed.contains(i) { continue }

            let current = assets[i]
            guard let currentDate = current.creationDate else { continue }

            var cluster: [PHAsset] = [current]
            processed.insert(i)

            for j in (i + 1)..<min(i + 50, assets.count) {
                if processed.contains(j) { continue }

                let candidate = assets[j]
                guard let candidateDate = candidate.creationDate else { continue }

                let timeDiff = abs(candidateDate.timeIntervalSince(currentDate))
                if timeDiff > 5.0 { break }

                let sameDimensions = current.pixelWidth == candidate.pixelWidth &&
                                     current.pixelHeight == candidate.pixelHeight

                let sameBurst = current.burstIdentifier != nil &&
                                current.burstIdentifier == candidate.burstIdentifier

                if sameDimensions || sameBurst {
                    cluster.append(candidate)
                    processed.insert(j)
                }
            }

            if cluster.count >= 2 {
                groups.append(cluster)
            }

            let p = Double(i) / Double(max(assets.count, 1))
            progress(min(p, 1.0))
        }

        progress(1.0)
        return groups
    }

    private func perceptualHashPass(assets: [PHAsset], progress: @escaping (Double) -> Void) async -> [[PHAsset]] {
        guard assets.count > 1 else { return [] }

        let batchSize = 50
        var hashes: [(asset: PHAsset, hash: UInt64)] = []

        for batchStart in stride(from: 0, to: assets.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, assets.count)
            let batch = Array(assets[batchStart..<batchEnd])

            let batchHashes = await withTaskGroup(of: (PHAsset, UInt64?).self, returning: [(PHAsset, UInt64)].self) { group in
                for asset in batch {
                    group.addTask {
                        let hash = await self.computeDHash(for: asset)
                        return (asset, hash)
                    }
                }

                var results: [(PHAsset, UInt64)] = []
                for await (asset, hash) in group {
                    if let hash = hash {
                        results.append((asset, hash))
                    }
                }
                return results
            }

            hashes.append(contentsOf: batchHashes)

            let p = Double(batchEnd) / Double(assets.count) * 0.7
            progress(p)
        }

        let groups = self.clusterByHammingDistance(hashes: hashes) { p in
            progress(0.7 + p * 0.3)
        }

        progress(1.0)
        return groups
    }

    private func computeDHash(for asset: PHAsset) async -> UInt64? {
        return await withCheckedContinuation { continuation in
            let targetSize = CGSize(width: (hashSize + 1) * 4, height: hashSize * 4)
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isSynchronous = true
            options.isNetworkAccessAllowed = false

            var result: UInt64?

            self.imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard let image = image,
                      let grayscalePixels = self.getGrayscalePixels(from: image,
                                                                      width: self.hashSize + 1,
                                                                      height: self.hashSize) else {
                    result = nil
                    return
                }

                var hash: UInt64 = 0
                var bit = 0

                for row in 0..<self.hashSize {
                    for col in 0..<self.hashSize {
                        let leftIdx = row * (self.hashSize + 1) + col
                        let rightIdx = row * (self.hashSize + 1) + col + 1

                        if grayscalePixels[leftIdx] < grayscalePixels[rightIdx] {
                            hash |= (1 << bit)
                        }
                        bit += 1
                    }
                }

                result = hash
            }

            continuation.resume(returning: result)
        }
    }

    /// Resizes an image and extracts grayscale pixel values using Accelerate framework.
    private func getGrayscalePixels(from image: UIImage, width: Int, height: Int) -> [UInt8]? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixels = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .low

        if let cgImage = image.cgImage {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return pixels
        } else if let ciImage = image.ciImage {
            let ciContext = CIContext(options: nil)
            if let renderedCG = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                context.draw(renderedCG, in: CGRect(x: 0, y: 0, width: width, height: height))
                return pixels
            }
        }

        return nil
    }

    private func hammingDistance(_ a: UInt64, _ b: UInt64) -> Int {
        return (a ^ b).nonzeroBitCount
    }

    private func clusterByHammingDistance(hashes: [(asset: PHAsset, hash: UInt64)],
                                          progress: @escaping (Double) -> Void) -> [[PHAsset]] {
        let n = hashes.count
        guard n > 1 else { return [] }

        var parent = Array(0..<n)
        var rank = Array(repeating: 0, count: n)

        func find(_ x: Int) -> Int {
            if parent[x] != x {
                parent[x] = find(parent[x])
            }
            return parent[x]
        }

        func union(_ x: Int, _ y: Int) {
            let px = find(x)
            let py = find(y)
            guard px != py else { return }
            if rank[px] < rank[py] {
                parent[px] = py
            } else if rank[px] > rank[py] {
                parent[py] = px
            } else {
                parent[py] = px
                rank[px] += 1
            }
        }

        let windowSize = n <= 2000 ? n : 200

        for i in 0..<n {
            let maxJ = min(i + windowSize, n)
            for j in (i + 1)..<maxJ {
                let dist = hammingDistance(hashes[i].hash, hashes[j].hash)
                if dist <= similarityThreshold {
                    union(i, j)
                }
            }

            if i % 50 == 0 {
                let p = Double(i) / Double(n)
                progress(min(p, 1.0))
            }
        }

        var groupMap: [Int: [PHAsset]] = [:]
        for i in 0..<n {
            let root = find(i)
            groupMap[root, default: []].append(hashes[i].asset)
        }

        progress(1.0)
        return Array(groupMap.values.filter { $0.count >= 2 })
    }

    func findBestPhoto(in assets: [PHAsset]) -> Int {
        var bestIndex = 0
        var bestScore = 0

        for (index, asset) in assets.enumerated() {
            var score = 0

            if asset.isFavorite { score += 10000 }

            let pixelCount = asset.pixelWidth * asset.pixelHeight
            score += pixelCount / 10000

            if asset.mediaSubtypes.contains(.photoScreenshot) {
                score -= 5000
            }

            if asset.burstSelectionTypes.contains(.autoPick) {
                score += 3000
            }
            if asset.burstSelectionTypes.contains(.userPick) {
                score += 5000
            }

            if score > bestScore {
                bestScore = score
                bestIndex = index
            }
        }

        return bestIndex
    }

    func findScreenshots() async -> [ScreenshotItem] {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let albums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: nil)
                if let screenshotsAlbum = albums.firstObject {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    let results = PHAsset.fetchAssets(in: screenshotsAlbum, options: fetchOptions)
                    var items: [ScreenshotItem] = []
                    items.reserveCapacity(results.count)
                    results.enumerateObjects { asset, _, _ in
                        items.append(ScreenshotItem(asset: asset))
                    }
                    continuation.resume(returning: items)
                    return
                }

                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

                let results = PHAsset.fetchAssets(with: fetchOptions)
                var items: [ScreenshotItem] = []
                results.enumerateObjects { asset, _, _ in
                    if asset.mediaSubtypes.contains(.photoScreenshot) {
                        items.append(ScreenshotItem(asset: asset))
                    }
                }

                continuation.resume(returning: items)
            }
        }
    }

    func totalPhotoCount() -> Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(with: fetchOptions).count
    }

    func estimateSize(of assets: [PHAsset]) async -> Int64 {
        var totalSize: Int64 = 0
        for asset in assets {
            let resources = PHAssetResource.assetResources(for: asset)
            var assetSize: Int64 = 0
            if let resource = resources.first {
                if let size = (resource.value(forKey: "fileSize") as? NSNumber)?.int64Value, size > 0 {
                    assetSize = size
                } else if let size = resource.value(forKey: "fileSize") as? Int64, size > 0 {
                    assetSize = size
                }
            }
            if assetSize == 0 {
                let pixelEstimate = Int64(asset.pixelWidth * asset.pixelHeight * 3 / 8)
                assetSize = pixelEstimate > 0 ? pixelEstimate : 3_000_000
            }
            totalSize += assetSize
        }
        return totalSize
    }

    func loadThumbnail(for asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast

        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    func loadFullImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            completion(image)
        }
    }
}
