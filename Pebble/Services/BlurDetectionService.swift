import Foundation
import Photos
import UIKit
import Accelerate

class BlurDetectionService {
    static let shared = BlurDetectionService()
    private let imageManager = PHCachingImageManager()
    private let blurThreshold: Float = 150.0
    private let analysisSize = CGSize(width: 256, height: 256)

    func findBlurryPhotos(progress: @escaping (Double) -> Void) async -> [BlurryPhotoItem] {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

                let results = PHAsset.fetchAssets(with: fetchOptions)
                let totalCount = results.count
                guard totalCount > 0 else {
                    continuation.resume(returning: [])
                    return
                }

                var blurryItems: [BlurryPhotoItem] = []
                let batchSize = 20

                for batchStart in stride(from: 0, to: totalCount, by: batchSize) {
                    let batchEnd = min(batchStart + batchSize, totalCount)

                    let batchResults = await withTaskGroup(of: BlurryPhotoItem?.self, returning: [BlurryPhotoItem].self) { group in
                        for i in batchStart..<batchEnd {
                            let asset = results.object(at: i)
                            if asset.mediaSubtypes.contains(.photoScreenshot) { continue }
                            group.addTask {
                                guard let variance = await self.computeLaplacianVariance(for: asset) else {
                                    return nil
                                }
                                if variance < self.blurThreshold {
                                    return BlurryPhotoItem(
                                        asset: asset,
                                        blurScore: variance,
                                        severity: self.blurSeverity(variance)
                                    )
                                }
                                return nil
                            }
                        }

                        var results: [BlurryPhotoItem] = []
                        for await item in group {
                            if let item = item {
                                results.append(item)
                            }
                        }
                        return results
                    }

                    blurryItems.append(contentsOf: batchResults)

                    let p = Double(batchEnd) / Double(totalCount)
                    progress(min(p, 1.0))
                }

                blurryItems.sort { $0.blurScore < $1.blurScore }

                progress(1.0)
                continuation.resume(returning: blurryItems)
            }
        }
    }

    private func computeLaplacianVariance(for asset: PHAsset) async -> Float? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isSynchronous = true
            options.isNetworkAccessAllowed = false

            var result: Float?

            self.imageManager.requestImage(
                for: asset,
                targetSize: self.analysisSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard let image = image else {
                    result = nil
                    return
                }

                if let cgImage = image.cgImage {
                    result = self.laplacianVariance(of: cgImage)
                } else if let ciImage = image.ciImage {
                    let ciContext = CIContext(options: nil)
                    if let renderedCG = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                        result = self.laplacianVariance(of: renderedCG)
                    }
                }
            }

            continuation.resume(returning: result)
        }
    }

    private func laplacianVariance(of cgImage: CGImage) -> Float? {
        let width = cgImage.width
        let height = cgImage.height
        guard width > 3, height > 3 else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        var grayPixels = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &grayPixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var laplacianValues: [Float] = []
        laplacianValues.reserveCapacity((width - 2) * (height - 2))

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let center = Float(grayPixels[y * width + x])
                let top    = Float(grayPixels[(y - 1) * width + x])
                let bottom = Float(grayPixels[(y + 1) * width + x])
                let left   = Float(grayPixels[y * width + (x - 1)])
                let right  = Float(grayPixels[y * width + (x + 1)])

                let lap = top + bottom + left + right - 4.0 * center
                laplacianValues.append(lap)
            }
        }

        guard !laplacianValues.isEmpty else { return nil }

        let count = Float(laplacianValues.count)
        let mean = laplacianValues.reduce(0, +) / count
        let variance = laplacianValues.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / count

        return variance
    }

    private func blurSeverity(_ variance: Float) -> BlurSeverity {
        if variance < 30 {
            return .veryBlurry
        } else if variance < 80 {
            return .blurry
        } else {
            return .slightlyBlurry
        }
    }
}

struct BlurryPhotoItem: Identifiable {
    let id: String
    let asset: PHAsset
    let blurScore: Float
    let severity: BlurSeverity
    var isSelected: Bool = false

    init(asset: PHAsset, blurScore: Float, severity: BlurSeverity) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.blurScore = blurScore
        self.severity = severity
    }
}

enum BlurSeverity: String {
    case veryBlurry = "Very Blurry"
    case blurry = "Blurry"
    case slightlyBlurry = "Slightly Blurry"

    var color: Color {
        switch self {
        case .veryBlurry: return Color(hex: "EF4444")
        case .blurry: return Color(hex: "F59E0B")
        case .slightlyBlurry: return Color(hex: "FBBF24")
        }
    }

    var icon: String {
        switch self {
        case .veryBlurry: return "exclamationmark.triangle.fill"
        case .blurry: return "camera.metering.unknown"
        case .slightlyBlurry: return "camera.metering.partial"
        }
    }
}

import SwiftUI
