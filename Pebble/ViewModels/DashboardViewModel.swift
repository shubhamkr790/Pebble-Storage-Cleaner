import SwiftUI
import Photos

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var storageInfo: StorageInfo = .placeholder
    @Published var categoryResults: [PebbleCategory: CategoryScanResult] = [:]
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var photoCount: Int = 0
    @Published var videoSizeFormatted: String = "—"
    @Published var freeableFormatted: String = "—"
    @Published var hasScanned = false

    private let storageService = StorageService.shared
    private let photoService = PhotoScanService.shared
    private let videoService = VideoScanService.shared
    private let contactService = ContactScanService.shared
    private let blurService = BlurDetectionService.shared

    @Published var similarPhotoGroups: [PhotoGroup] = []
    @Published var screenshots: [ScreenshotItem] = []
    @Published var largeVideos: [VideoItem] = []
    @Published var duplicateContacts: [DuplicateContactGroup] = []
    @Published var blurryPhotos: [BlurryPhotoItem] = []

    init() {
        for category in PebbleCategory.allCases {
            categoryResults[category] = CategoryScanResult(
                category: category,
                itemCount: 0,
                freeableBytes: 0,
                isScanned: false
            )
        }
        loadStorageInfo()
    }

    func loadStorageInfo() {
        storageInfo = storageService.getStorageInfo()
        photoCount = photoService.totalPhotoCount()
    }

    func runDeepScan() async {
        guard !isScanning else { return }
        isScanning = true
        scanProgress = 0

        loadStorageInfo()

        similarPhotoGroups = await photoService.findSimilarPhotos { [weak self] progress in
            Task { @MainActor in self?.scanProgress = progress * 0.3 }
        }
        let similarCount = similarPhotoGroups.reduce(0) { $0 + $1.assets.count - 1 }
        let similarAssets = similarPhotoGroups.flatMap { $0.selectedAssets }
        let similarSize = await photoService.estimateSize(of: similarAssets)
        categoryResults[.similarPhotos] = CategoryScanResult(
            category: .similarPhotos, itemCount: similarCount,
            freeableBytes: similarSize, isScanned: true
        )

        screenshots = await photoService.findScreenshots()
        let screenshotAssets = screenshots.map { $0.asset }
        let screenshotSize = await photoService.estimateSize(of: screenshotAssets)
        categoryResults[.screenshots] = CategoryScanResult(
            category: .screenshots, itemCount: screenshots.count,
            freeableBytes: screenshotSize, isScanned: true
        )
        scanProgress = 0.4

        largeVideos = await videoService.findLargeVideos { [weak self] progress in
            Task { @MainActor in self?.scanProgress = 0.4 + progress * 0.2 }
        }
        let videoSize = largeVideos.reduce(Int64(0)) { $0 + $1.fileSize }
        categoryResults[.largeVideos] = CategoryScanResult(
            category: .largeVideos, itemCount: largeVideos.count,
            freeableBytes: videoSize, isScanned: true
        )
        videoSizeFormatted = ByteCountFormatter.string(fromByteCount: videoSize, countStyle: .file)

        let permService = PermissionService.shared
        if permService.isContactAuthorized {
            duplicateContacts = await contactService.findDuplicates()
            categoryResults[.duplicateContacts] = CategoryScanResult(
                category: .duplicateContacts, itemCount: duplicateContacts.count,
                freeableBytes: 0, isScanned: true
            )
        }
        scanProgress = 0.65

        blurryPhotos = await blurService.findBlurryPhotos { [weak self] progress in
            Task { @MainActor in self?.scanProgress = 0.65 + progress * 0.35 }
        }
        let blurryAssets = blurryPhotos.map { $0.asset }
        let blurrySize = await photoService.estimateSize(of: blurryAssets)
        categoryResults[.blurryPhotos] = CategoryScanResult(
            category: .blurryPhotos, itemCount: blurryPhotos.count,
            freeableBytes: blurrySize, isScanned: true
        )

        scanProgress = 1.0

        let totalFreeable = categoryResults.values.reduce(Int64(0)) { $0 + $1.freeableBytes }
        freeableFormatted = ByteCountFormatter.string(fromByteCount: totalFreeable, countStyle: .file)

        isScanning = false
        hasScanned = true

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
