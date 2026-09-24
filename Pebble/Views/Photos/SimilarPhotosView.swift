import SwiftUI
import Photos

struct SimilarPhotosView: View {
    @StateObject private var viewModel = SimilarPhotosViewModel()
    let initialGroups: [PhotoGroup]
    let onReview: ([PHAsset]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var estimatedSavings = "Calculating..."

    var body: some View {
        Group {
            if viewModel.groups.isEmpty {
                EmptyStateView(
                    title: "No Similar Photos Found",
                    message: "Your photo library looks clean! No duplicate or similar photos were detected.",
                    icon: "photo.badge.checkmark",
                    showSettingsButton: false
                )
            } else {
                photoGroupsList
                    .safeAreaInset(edge: .bottom) {
                        if viewModel.totalSelectedCount > 0 {
                            FloatingActionBar(
                                itemCount: viewModel.totalSelectedCount,
                                totalSize: estimatedSavings,
                                actionTitle: "Review"
                            ) {
                                onReview(viewModel.selectedAssets)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.totalSelectedCount)
        .navigationTitle("Similar Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Select All Duplicates") { viewModel.selectAllGroups() }
                    Button("Deselect All") { viewModel.deselectAllGroups() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.pebbleSage)
                }
            }
        }
        .onAppear {
            viewModel.loadGroups(from: initialGroups)
            Task {
                estimatedSavings = await viewModel.estimatedSavings()
            }
        }
        .onChange(of: viewModel.totalSelectedCount) { _, _ in
            Task {
                estimatedSavings = await viewModel.estimatedSavings()
            }
        }
    }

    private var photoGroupsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 24) {
                HStack {
                    Text("\(viewModel.groups.count) groups found")
                        .pebbleBody()
                    Spacer()
                }
                .padding(.horizontal, PebbleLayout.screenPadding)

                ForEach(Array(viewModel.groups.enumerated()), id: \.element.id) { groupIndex, group in
                    PhotoClusterView(
                        group: group,
                        groupIndex: groupIndex,
                        onToggleSelection: { assetIndex in
                            viewModel.toggleSelection(groupIndex: groupIndex, assetIndex: assetIndex)
                        },
                        onSelectAllExceptBest: {
                            viewModel.selectAllExceptBest(in: groupIndex)
                        },
                        onDeselectAll: {
                            viewModel.deselectAll(in: groupIndex)
                        }
                    )
                }
            }
            .padding(.bottom, 16)
        }
    }
}

struct PhotoClusterView: View {
    let group: PhotoGroup
    let groupIndex: Int
    let onToggleSelection: (Int) -> Void
    let onSelectAllExceptBest: () -> Void
    let onDeselectAll: () -> Void
    @State private var showFullImage = false
    @State private var selectedAssetForPreview: PHAsset?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Group \(groupIndex + 1)")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.pebbleObsidian)

                Text("• \(group.assets.count) photos")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.pebbleStone)

                Spacer()

                Button {
                    if group.selectedIndices.isEmpty {
                        onSelectAllExceptBest()
                    } else {
                        onDeselectAll()
                    }
                } label: {
                    Text(group.selectedIndices.isEmpty ? "Select Duplicates" : "Deselect All")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.pebbleSage)
                }
            }
            .padding(.horizontal, PebbleLayout.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(group.assets.enumerated()), id: \.element.localIdentifier) { index, asset in
                        photoThumbnail(asset: asset, index: index)
                    }
                }
                .padding(.horizontal, PebbleLayout.screenPadding)
            }
        }
        .sheet(item: $selectedAssetForPreview) { asset in
            FullImageView(asset: asset)
        }
    }

    private func photoThumbnail(asset: PHAsset, index: Int) -> some View {
        let isBest = index == group.bestPickIndex
        let isSelected = group.selectedIndices.contains(index)

        return ZStack(alignment: .topLeading) {
            AssetThumbnailView(asset: asset, size: CGSize(width: 240, height: 240))
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if !isBest {
                PebbleSelectionOverlay(isSelected: isSelected)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if isBest {
                VStack {
                    Spacer()
                    BestPickBadge()
                        .padding(6)
                }
                .frame(width: 120, height: 120)
            }
        }
        .onTapGesture {
            if isBest {
                selectedAssetForPreview = asset
            } else {
                onToggleSelection(index)
            }
        }
        .onLongPressGesture {
            selectedAssetForPreview = asset
        }
    }
}

extension PHAsset: @retroactive Identifiable {
    public var id: String { localIdentifier }
}
