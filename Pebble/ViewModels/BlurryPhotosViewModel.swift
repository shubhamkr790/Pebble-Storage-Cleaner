import SwiftUI
import Photos

@MainActor
class BlurryPhotosViewModel: ObservableObject {
    @Published var items: [BlurryPhotoItem] = []
    @Published var isLoading = false

    var selectedCount: Int {
        items.filter { $0.isSelected }.count
    }

    var selectedAssets: [PHAsset] {
        items.filter { $0.isSelected }.map { $0.asset }
    }

    var totalCount: Int { items.count }

    func loadItems(from cached: [BlurryPhotoItem]) {
        self.items = cached
    }

    func toggleSelection(id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isSelected.toggle()
    }

    func selectAll() {
        for i in items.indices { items[i].isSelected = true }
    }

    func deselectAll() {
        for i in items.indices { items[i].isSelected = false }
    }

    func estimatedSavings() async -> String {
        let size = await PhotoScanService.shared.estimateSize(of: selectedAssets)
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
