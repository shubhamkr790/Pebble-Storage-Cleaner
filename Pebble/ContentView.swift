import SwiftUI
import Photos

struct SwipeSession: Identifiable {
    let id = UUID()
    let assets: [PHAsset]
}

struct CleanupSession: Identifiable {
    let id = UUID()
    let plan: CleanupPlan
    let estimatedSize: Int64
}

struct ContentView: View {
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    @State private var showSimilarPhotos = false
    @State private var showScreenshots = false
    @State private var showLargeVideos = false
    @State private var showDuplicateContacts = false
    @State private var showBlurryPhotos = false

    @State private var swipeSession: SwipeSession?

    @State private var cleanupSession: CleanupSession?
    @State private var showCleanupComplete = false
    @State private var cleanupResult: CleanupResult = .empty

    var body: some View {
        NavigationStack {
            dashboardContent
                .navigationDestination(isPresented: $showSimilarPhotos) {
                    SimilarPhotosView(initialGroups: dashboardVM.similarPhotoGroups) { selectedAssets in
                        prepareSimilarPhotoCleanup(selectedAssets)
                    }
                }
                .navigationDestination(isPresented: $showScreenshots) {
                    ScreenshotsView(initialScreenshots: dashboardVM.screenshots) { selectedAssets in
                        prepareScreenshotCleanup(selectedAssets)
                    }
                }
                .navigationDestination(isPresented: $showLargeVideos) {
                    LargeVideosView(initialVideos: dashboardVM.largeVideos) { selectedAssets in
                        prepareVideoCleanup(selectedAssets)
                    }
                }
                .navigationDestination(isPresented: $showDuplicateContacts) {
                    DuplicateContactsView(
                        permissionService: permissionService,
                        initialGroups: dashboardVM.duplicateContacts
                    )
                }
                .navigationDestination(isPresented: $showBlurryPhotos) {
                    BlurryPhotosView(initialItems: dashboardVM.blurryPhotos) { selectedAssets in
                        prepareBlurryPhotoCleanup(selectedAssets)
                    }
                }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            } else {
                checkPermissionsAndLoad()
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                showOnboarding = false
                hasCompletedOnboarding = true
                requestPhotoPermission()
            }
        }
        .fullScreenCover(item: $swipeSession) { session in
            SwipeReviewView(assets: session.assets) { assetsToDelete in
                swipeSession = nil
                if !assetsToDelete.isEmpty {
                    prepareSimilarPhotoCleanup(assetsToDelete)
                }
            }
        }
        .sheet(item: $cleanupSession) { session in
            ReviewCleanupView(
                plan: session.plan,
                estimatedSize: session.estimatedSize,
                onConfirm: {
                    let planToExecute = session.plan
                    cleanupSession = nil
                    executeCleanup(planToExecute)
                },
                onCancel: {
                    cleanupSession = nil
                }
            )
        }
        .fullScreenCover(isPresented: $showCleanupComplete) {
            CleanupCompleteView(result: cleanupResult) {
                showCleanupComplete = false
                showSimilarPhotos = false
                showScreenshots = false
                showLargeVideos = false
                showBlurryPhotos = false
                dashboardVM.loadStorageInfo()
                Task { await dashboardVM.runDeepScan() }
            }
        }
    }

    private var dashboardContent: some View {
        Group {
            if permissionService.isPhotoDenied {
                EmptyStateView(
                    title: "Photo Access Required",
                    message: "Pebble needs access to your photo library to scan for duplicates and free up storage. Please grant access in Settings.",
                    icon: "photo.badge.exclamationmark"
                )
            } else if permissionService.photoAuthStatus == .notDetermined {
                PermissionPromptView(type: .photos) {
                    requestPhotoPermission()
                }
            } else {
                DashboardView(
                    viewModel: dashboardVM,
                    permissionService: permissionService,
                    onNavigate: { category in
                        navigateToCategory(category)
                    },
                    onSwipeMode: {
                        var candidateAssets = dashboardVM.similarPhotoGroups.flatMap { $0.assets }
                        if candidateAssets.isEmpty {
                            candidateAssets = dashboardVM.screenshots.map { $0.asset }
                        }
                        if candidateAssets.isEmpty {
                            candidateAssets = dashboardVM.blurryPhotos.map { $0.asset }
                        }
                        if !candidateAssets.isEmpty {
                            swipeSession = SwipeSession(assets: candidateAssets)
                        }
                    }
                )
            }
        }
    }

    private func navigateToCategory(_ category: PebbleCategory) {
        switch category {
        case .similarPhotos:
            showSimilarPhotos = true
        case .screenshots:
            showScreenshots = true
        case .largeVideos:
            showLargeVideos = true
        case .duplicateContacts:
            showDuplicateContacts = true
        case .blurryPhotos:
            showBlurryPhotos = true
        }
    }

    private func checkPermissionsAndLoad() {
        permissionService.refreshStatuses()
        if permissionService.isPhotoAuthorized || permissionService.isPhotoLimited {
            dashboardVM.loadStorageInfo()
        }
    }

    private func requestPhotoPermission() {
        Task {
            let status = await permissionService.requestPhotoAccess()
            if status == .authorized || status == .limited {
                dashboardVM.loadStorageInfo()
            }
        }
    }

    private func prepareSimilarPhotoCleanup(_ assets: [PHAsset]) {
        Task {
            let size = await PhotoScanService.shared.estimateSize(of: assets)
            let plan = CleanupPlan(photoAssets: assets)
            await MainActor.run {
                self.cleanupSession = CleanupSession(plan: plan, estimatedSize: size)
            }
        }
    }

    private func prepareScreenshotCleanup(_ assets: [PHAsset]) {
        Task {
            let size = await PhotoScanService.shared.estimateSize(of: assets)
            let plan = CleanupPlan(screenshotAssets: assets)
            await MainActor.run {
                self.cleanupSession = CleanupSession(plan: plan, estimatedSize: size)
            }
        }
    }

    private func prepareVideoCleanup(_ assets: [PHAsset]) {
        let size = assets.reduce(Int64(0)) { total, asset in
            let resources = PHAssetResource.assetResources(for: asset)
            let resSize = (resources.first?.value(forKey: "fileSize") as? NSNumber)?.int64Value ?? 0
            return total + (resSize > 0 ? resSize : 15_000_000)
        }
        let plan = CleanupPlan(videoAssets: assets)
        cleanupSession = CleanupSession(plan: plan, estimatedSize: size)
    }

    private func prepareBlurryPhotoCleanup(_ assets: [PHAsset]) {
        Task {
            let size = await PhotoScanService.shared.estimateSize(of: assets)
            let plan = CleanupPlan(photoAssets: assets)
            await MainActor.run {
                self.cleanupSession = CleanupSession(plan: plan, estimatedSize: size)
            }
        }
    }

    private func executeCleanup(_ plan: CleanupPlan) {
        Task {
            cleanupResult = await CleanupService.shared.executeCleanup(plan)
            showCleanupComplete = true
        }
    }
}
