import SwiftUI
import Photos

@MainActor
class LargeVideosViewModel: ObservableObject {
    @Published var videos: [VideoItem] = []
    @Published var isLoading = false

    var selectedCount: Int {
        videos.filter { $0.isSelected }.count
    }

    var selectedAssets: [PHAsset] {
        videos.filter { $0.isSelected }.map { $0.asset }
    }

    var selectedTotalSize: Int64 {
        videos.filter { $0.isSelected }.reduce(Int64(0)) { $0 + $1.fileSize }
    }

    var selectedTotalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: selectedTotalSize, countStyle: .file)
    }

    func loadVideos(from cached: [VideoItem]) {
        self.videos = cached
    }

    func toggleSelection(at index: Int) {
        guard index < videos.count else { return }
        videos[index].isSelected.toggle()
    }

    func toggleById(_ id: String) {
        guard let index = videos.firstIndex(where: { $0.id == id }) else { return }
        videos[index].isSelected.toggle()
    }

    func selectAll() {
        for i in videos.indices {
            videos[i].isSelected = true
        }
    }

    func deselectAll() {
        for i in videos.indices {
            videos[i].isSelected = false
        }
    }
}
