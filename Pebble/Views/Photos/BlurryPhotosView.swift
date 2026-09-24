import SwiftUI
import Photos

struct BlurryPhotosView: View {
    @StateObject private var viewModel = BlurryPhotosViewModel()
    let initialItems: [BlurryPhotoItem]
    let onReview: ([PHAsset]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var estimatedSavings = "Calculating..."
    @State private var previewAsset: PHAsset?

    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                EmptyStateView(
                    title: "No Blurry Photos Found",
                    message: "Your photo library looks sharp! No blurry photos were detected.",
                    icon: "checkmark.circle.fill",
                    showSettingsButton: false
                )
            } else {
                blurryGrid
                    .safeAreaInset(edge: .bottom) {
                        if viewModel.selectedCount > 0 {
                            FloatingActionBar(
                                itemCount: viewModel.selectedCount,
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
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.selectedCount)
        .navigationTitle("Blurry Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Select All") { viewModel.selectAll() }
                    Button("Deselect All") { viewModel.deselectAll() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.pebbleSage)
                }
            }
        }
        .onAppear {
            viewModel.loadItems(from: initialItems)
        }
        .onChange(of: viewModel.selectedCount) { _, _ in
            Task { estimatedSavings = await viewModel.estimatedSavings() }
        }
        .sheet(item: $previewAsset) { asset in
            FullImageView(asset: asset)
        }
    }

    private var blurryGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(viewModel.totalCount) blurry photos found")
                        .pebbleBody()
                    Spacer()
                }
                .padding(.horizontal, PebbleLayout.screenPadding)

                LazyVGrid(columns: columns, spacing: 3) {
                    ForEach(viewModel.items, id: \.id) { item in
                        blurryCell(item: item)
                    }
                }
                .padding(.horizontal, 3)
            }
            .padding(.bottom, 16)
        }
    }

    private func blurryCell(item: BlurryPhotoItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            AssetThumbnailView(asset: item.asset, size: CGSize(width: 300, height: 300))
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .clipped()

            PebbleSelectionOverlay(isSelected: item.isSelected)

            HStack(spacing: 3) {
                Image(systemName: item.severity.icon)
                    .font(.system(size: 8, weight: .bold))
                Text(item.severity.rawValue)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(item.severity.color.opacity(0.85))
            )
            .padding(5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .onTapGesture {
            viewModel.toggleSelection(id: item.id)
        }
        .onLongPressGesture {
            previewAsset = item.asset
        }
    }
}
