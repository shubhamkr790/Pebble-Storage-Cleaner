import SwiftUI
import Photos

@MainActor
class ScreenshotsViewModel: ObservableObject {
    @Published var monthGroups: [ScreenshotMonthGroup] = []
    @Published var isLoading = false

    var totalSelectedCount: Int {
        monthGroups.reduce(0) { $0 + $1.selectedCount }
    }

    var selectedAssets: [PHAsset] {
        monthGroups.flatMap { group in
            group.items.filter { $0.isSelected }.map { $0.asset }
        }
    }

    var totalCount: Int {
        monthGroups.reduce(0) { $0 + $1.items.count }
    }

    func loadScreenshots(from cached: [ScreenshotItem]) {
        var grouped: [String: [ScreenshotItem]] = [:]
        for item in cached {
            let key = item.monthKey
            grouped[key, default: []].append(item)
        }

        let sortedKeys = grouped.keys.sorted { key1, key2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let date1 = formatter.date(from: key1) ?? .distantPast
            let date2 = formatter.date(from: key2) ?? .distantPast
            return date1 > date2
        }

        monthGroups = sortedKeys.map { key in
            ScreenshotMonthGroup(id: key, monthTitle: key, items: grouped[key] ?? [])
        }
    }

    func toggleItem(monthId: String, itemId: String) {
        guard let monthIndex = monthGroups.firstIndex(where: { $0.id == monthId }),
              let itemIndex = monthGroups[monthIndex].items.firstIndex(where: { $0.id == itemId }) else { return }
        monthGroups[monthIndex].items[itemIndex].isSelected.toggle()
    }

    func toggleSelectAllInMonth(_ monthId: String) {
        guard let monthIndex = monthGroups.firstIndex(where: { $0.id == monthId }) else { return }
        let allSelected = monthGroups[monthIndex].allSelected
        for i in monthGroups[monthIndex].items.indices {
            monthGroups[monthIndex].items[i].isSelected = !allSelected
        }
    }

    func selectAll() {
        for i in monthGroups.indices {
            for j in monthGroups[i].items.indices {
                monthGroups[i].items[j].isSelected = true
            }
        }
    }

    func deselectAll() {
        for i in monthGroups.indices {
            for j in monthGroups[i].items.indices {
                monthGroups[i].items[j].isSelected = false
            }
        }
    }

    func estimatedSavings() async -> String {
        let size = await PhotoScanService.shared.estimateSize(of: selectedAssets)
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
