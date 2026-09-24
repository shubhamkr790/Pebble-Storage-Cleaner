import SwiftUI
import Photos

@MainActor
class SwipeReviewViewModel: ObservableObject {
    @Published var assets: [PHAsset]
    @Published var currentIndex: Int = 0
    @Published var keepList: [PHAsset] = []
    @Published var deleteList: [PHAsset] = []
    @Published var isComplete = false

    init(assets: [PHAsset] = []) {
        self.assets = assets
        self.currentIndex = 0
        self.keepList = []
        self.deleteList = []
        self.isComplete = assets.isEmpty
    }

    var currentAsset: PHAsset? {
        guard currentIndex < assets.count else { return nil }
        return assets[currentIndex]
    }

    var nextAsset: PHAsset? {
        guard currentIndex + 1 < assets.count else { return nil }
        return assets[currentIndex + 1]
    }

    var progress: Double {
        guard !assets.isEmpty else { return 0 }
        return Double(currentIndex) / Double(assets.count)
    }

    var remaining: Int {
        max(assets.count - currentIndex, 0)
    }

    var currentFormattedDate: String {
        guard let date = currentAsset?.creationDate else { return "Unknown date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var currentDimensions: String {
        guard let asset = currentAsset else { return "" }
        return "\(asset.pixelWidth) × \(asset.pixelHeight)"
    }

    var currentFileSizeFormatted: String {
        guard let asset = currentAsset else { return "" }
        let resources = PHAssetResource.assetResources(for: asset)
        if let res = resources.first, let size = res.value(forKey: "fileSize") as? Int64 {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        return ""
    }

    func loadAssets(_ newAssets: [PHAsset]) {
        self.assets = newAssets
        self.currentIndex = 0
        self.keepList = []
        self.deleteList = []
        self.isComplete = newAssets.isEmpty
    }

    func swipeKeep() {
        guard let asset = currentAsset else { return }
        keepList.append(asset)
        advance()
    }

    func swipeDelete() {
        guard let asset = currentAsset else { return }
        deleteList.append(asset)
        advance()
    }

    func undo() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        isComplete = false
        if let idx = keepList.lastIndex(where: { $0.localIdentifier == assets[currentIndex].localIdentifier }) {
            keepList.remove(at: idx)
        }
        if let idx = deleteList.lastIndex(where: { $0.localIdentifier == assets[currentIndex].localIdentifier }) {
            deleteList.remove(at: idx)
        }
    }

    private func advance() {
        if currentIndex + 1 < assets.count {
            currentIndex += 1
        } else {
            isComplete = true
        }
    }
}
