import SwiftUI
import Photos

struct ScreenshotsView: View {
    @StateObject private var viewModel = ScreenshotsViewModel()
    let initialScreenshots: [ScreenshotItem]
    let onReview: ([PHAsset]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var estimatedSavings = "Calculating..."
    @State private var previewAsset: PHAsset?

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        Group {
            if viewModel.monthGroups.isEmpty {
                EmptyStateView(
                    title: "No Screenshots Found",
                    message: "You don't have any screenshots in your photo library.",
                    icon: "rectangle.portrait.on.rectangle.portrait.slash",
                    showSettingsButton: false
                )
            } else {
                screenshotGrid
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
        .navigationTitle("Screenshots")
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
            viewModel.loadScreenshots(from: initialScreenshots)
        }
        .onChange(of: viewModel.totalSelectedCount) { _, _ in
            Task {
                estimatedSavings = await viewModel.estimatedSavings()
            }
        }
        .sheet(item: $previewAsset) { asset in
            FullImageView(asset: asset)
        }
    }

    private var screenshotGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                ForEach($viewModel.monthGroups) { $monthGroup in
                    Section {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(monthGroup.items, id: \.id) { item in
                                screenshotCell(item: item, monthId: monthGroup.id)
                            }
                        }
                        .padding(.horizontal, PebbleLayout.screenPadding)
                    } header: {
                        monthHeader(monthGroup: monthGroup)
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }

    private func monthHeader(monthGroup: ScreenshotMonthGroup) -> some View {
        HStack {
            Text(monthGroup.monthTitle)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.pebbleObsidian)

            Text("(\(monthGroup.items.count))")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.pebbleStone)

            Spacer()

            Button {
                viewModel.toggleSelectAllInMonth(monthGroup.id)
            } label: {
                Text(monthGroup.allSelected ? "Deselect All" : "Select All")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(.pebbleSage)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.pebbleSage.opacity(0.08))
                    )
            }
        }
        .padding(.horizontal, PebbleLayout.screenPadding)
        .padding(.vertical, 10)
        .background(Color.pebbleCanvas)
    }

    private func screenshotCell(item: ScreenshotItem, monthId: String) -> some View {
        ZStack(alignment: .topTrailing) {
            AssetThumbnailView(asset: item.asset, size: CGSize(width: 300, height: 500))
                .frame(maxWidth: .infinity)
                .aspectRatio(9/16, contentMode: .fill)
                .clipped()

            Circle()
                .fill(item.isSelected ? Color.pebbleSage : Color.black.opacity(0.25))
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(item.isSelected ? 1 : 0)
                )
                .frame(width: 24, height: 24)
                .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    item.isSelected ? Color.pebbleSage : Color.clear,
                    lineWidth: 2.5
                )
        )
        .shadow(color: item.isSelected ? Color.pebbleSage.opacity(0.15) : Color.black.opacity(0.06), radius: item.isSelected ? 8 : 4, x: 0, y: 2)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                viewModel.toggleItem(monthId: monthId, itemId: item.id)
            }
        }
        .onLongPressGesture {
            previewAsset = item.asset
        }
    }
}
