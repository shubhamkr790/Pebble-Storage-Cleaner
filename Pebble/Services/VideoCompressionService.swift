import Foundation
import Photos
import AVFoundation

class VideoCompressionService {
    static let shared = VideoCompressionService()

    enum CompressionQuality: String, CaseIterable {
        case medium = "Medium (720p)"
        case high = "High (1080p)"

        var preset: String {
            switch self {
            case .medium: return AVAssetExportPreset1280x720
            case .high: return AVAssetExportPreset1920x1080
            }
        }

        var estimatedRatio: Double {
            switch self {
            case .medium: return 0.3
            case .high: return 0.5
            }
        }
    }

    func compressVideo(
        asset: PHAsset,
        quality: CompressionQuality = .medium,
        progress: @escaping (Double) -> Void
    ) async throws -> Int64 {
        let videoURL = try await getVideoURL(for: asset)
        let avAsset = AVURLAsset(url: videoURL)

        guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: quality.preset) else {
            throw CompressionError.exportSessionFailed
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        let progressTask = Task {
            while !Task.isCancelled {
                let p = Double(exportSession.progress)
                progress(min(p, 0.9))
                try await Task.sleep(nanoseconds: 200_000_000)
            }
        }

        await exportSession.export()
        progressTask.cancel()

        guard exportSession.status == .completed else {
            try? FileManager.default.removeItem(at: outputURL)
            throw CompressionError.exportFailed(exportSession.error?.localizedDescription ?? "Unknown error")
        }

        let originalSize = try self.fileSize(at: videoURL)
        let compressedSize = try self.fileSize(at: outputURL)
        let savedBytes = originalSize - compressedSize

        guard savedBytes > 0 else {
            try? FileManager.default.removeItem(at: outputURL)
            throw CompressionError.noSavings
        }

        progress(0.9)
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
            request?.creationDate = asset.creationDate
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets([asset] as NSFastEnumeration)
        }

        try? FileManager.default.removeItem(at: outputURL)

        progress(1.0)
        return savedBytes
    }

    func estimateSavings(for video: VideoItem, quality: CompressionQuality = .medium) -> Int64 {
        let estimatedCompressed = Int64(Double(video.fileSize) * quality.estimatedRatio)
        return max(video.fileSize - estimatedCompressed, 0)
    }

    private func getVideoURL(for asset: PHAsset) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = false
            options.version = .current

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard let urlAsset = avAsset as? AVURLAsset else {
                    continuation.resume(throwing: CompressionError.videoNotFound)
                    return
                }
                continuation.resume(returning: urlAsset.url)
            }
        }
    }

    private func fileSize(at url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
}

enum CompressionError: LocalizedError {
    case exportSessionFailed
    case exportFailed(String)
    case videoNotFound
    case noSavings

    var errorDescription: String? {
        switch self {
        case .exportSessionFailed: return "Could not create export session."
        case .exportFailed(let msg): return "Export failed: \(msg)"
        case .videoNotFound: return "Could not access video file."
        case .noSavings: return "Compression didn't reduce file size."
        }
    }
}
