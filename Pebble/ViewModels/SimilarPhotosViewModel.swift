import SwiftUI
import Photos

@MainActor
class SimilarPhotosViewModel: ObservableObject {
    @Published var groups: [PhotoGroup] = []
    @Published var isLoading = false

    var totalSelectedCount: Int {
        groups.reduce(0) { $0 + $1.selectedIndices.count }
    }

    var selectedAssets: [PHAsset] {
        groups.flatMap { $0.selectedAssets }
    }

    func loadGroups(from cached: [PhotoGroup]) {
        self.groups = cached
    }

    func selectAllExceptBest(in groupIndex: Int) {
        guard groupIndex < groups.count else { return }
        groups[groupIndex].selectAllExceptBest()
    }

    func deselectAll(in groupIndex: Int) {
        guard groupIndex < groups.count else { return }
        groups[groupIndex].deselectAll()
    }

    func toggleSelection(groupIndex: Int, assetIndex: Int) {
        guard groupIndex < groups.count else { return }
        groups[groupIndex].toggleSelection(at: assetIndex)
    }

    func selectAllGroups() {
        for i in groups.indices {
            groups[i].selectAllExceptBest()
        }
    }

    func deselectAllGroups() {
        for i in groups.indices {
            groups[i].deselectAll()
        }
    }

    func estimatedSavings() async -> String {
        let size = await PhotoScanService.shared.estimateSize(of: selectedAssets)
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
