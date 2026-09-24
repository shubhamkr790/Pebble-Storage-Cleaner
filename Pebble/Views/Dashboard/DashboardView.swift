import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var permissionService: PermissionService
    let onNavigate: (PebbleCategory) -> Void
    let onSwipeMode: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: PebbleLayout.sectionSpacing) {
                headerSection

                if permissionService.isPhotoLimited {
                    LimitedAccessBanner()
                }

                storageRingSection
                quickStatsSection
                scanButtonSection
                categoryCardsSection

                if viewModel.hasScanned && (!viewModel.similarPhotoGroups.isEmpty || !viewModel.screenshots.isEmpty || !viewModel.blurryPhotos.isEmpty) {
                    quickActionsSection
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color.pebbleCanvas.ignoresSafeArea())
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pebble")
                    .pebbleTitle()

                Text("Your storage, tidied up")
                    .pebbleBody()
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pebbleMint.opacity(0.2), .pebbleSage.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text("🪨")
                    .font(.system(size: 24))
            }
        }
        .padding(.horizontal, PebbleLayout.screenPadding)
    }

    private var storageRingSection: some View {
        StorageRingView(storageInfo: viewModel.storageInfo)
            .padding(.vertical, 8)
    }

    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            StatPill(
                icon: "photo.fill",
                value: "\(viewModel.photoCount)",
                label: "Photos",
                color: .pebbleCoral
            )

            StatPill(
                icon: "film.fill",
                value: viewModel.videoSizeFormatted,
                label: "Videos",
                color: .pebbleViolet
            )

            StatPill(
                icon: "arrow.up.bin.fill",
                value: viewModel.freeableFormatted,
                label: "Freeable",
                color: .pebbleSage
            )
        }
        .padding(.horizontal, PebbleLayout.screenPadding)
    }

    private var scanButtonSection: some View {
        VStack(spacing: 12) {
            if viewModel.isScanning {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.scanProgress)
                        .tint(.pebbleSage)
                        .scaleEffect(y: 2)

                    Text("Scanning your library...")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(.pebbleStone)
                }
                .padding(.horizontal, PebbleLayout.screenPadding)
            } else {
                PebblePillButton(
                    viewModel.hasScanned ? "Scan Again" : "Deep Library Scan",
                    icon: "magnifyingglass"
                ) {
                    Task {
                        await viewModel.runDeepScan()
                    }
                }
            }
        }
    }

    private var categoryCardsSection: some View {
        VStack(spacing: 12) {
            Text("Categories")
                .pebbleHeadline()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PebbleLayout.screenPadding)

            ForEach(PebbleCategory.allCases) { category in
                let result = viewModel.categoryResults[category] ?? CategoryScanResult(
                    category: category,
                    itemCount: 0,
                    freeableBytes: 0
                )

                CategoryCardView(result: result) {
                    navigateToCategory(category)
                }
                .padding(.horizontal, PebbleLayout.screenPadding)
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .pebbleHeadline()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PebbleLayout.screenPadding)

            Button(action: onSwipeMode) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pebbleSage.opacity(0.15), .pebbleMint.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.pebbleSage)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Swipe Mode")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(.pebbleObsidian)

                        Text("Tinder-style photo review — swipe to keep or delete")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.pebbleStone)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.pebbleStone.opacity(0.5))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: PebbleLayout.cardRadius, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: PebbleLayout.cardRadius, style: .continuous)
                                .stroke(Color.pebbleSage.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .pebbleCardShadow, radius: 16, x: 0, y: 6)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, PebbleLayout.screenPadding)
        }
    }

    private func navigateToCategory(_ category: PebbleCategory) {
        onNavigate(category)
    }
}
