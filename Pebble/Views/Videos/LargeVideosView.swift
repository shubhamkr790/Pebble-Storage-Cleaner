import SwiftUI
import Photos
import AVKit

struct LargeVideosView: View {
    @StateObject private var viewModel = LargeVideosViewModel()
    let initialVideos: [VideoItem]
    let onReview: ([PHAsset]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var compressingVideoId: String?
    @State private var compressionProgress: Double = 0
    @State private var showCompressionResult = false
    @State private var lastCompressionSaved: Int64 = 0
    @State private var compressionError: String?
    @State private var compressionTask: Task<Void, Never>?

    @State private var videoToCompress: VideoItem?
    @State private var showCompressConfirmation = false

    var body: some View {
        Group {
            if viewModel.videos.isEmpty {
                EmptyStateView(
                    title: "No Videos Found",
                    message: "Your library doesn't contain any videos to review.",
                    icon: "film.stack.fill",
                    showSettingsButton: false
                )
            } else {
                videoList
                    .safeAreaInset(edge: .bottom) {
                        if viewModel.selectedCount > 0 && compressingVideoId == nil {
                            FloatingActionBar(
                                itemCount: viewModel.selectedCount,
                                totalSize: viewModel.selectedTotalSizeFormatted,
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
        .navigationTitle("Large Videos")
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
            viewModel.loadVideos(from: initialVideos)
        }
        .alert("Compression Result", isPresented: $showCompressionResult) {
            Button("OK") {
                showCompressionResult = false
                compressionError = nil
            }
        } message: {
            if let error = compressionError {
                Text(error)
            } else {
                Text("Saved \(ByteCountFormatter.string(fromByteCount: lastCompressionSaved, countStyle: .file))! 🎉")
            }
        }
        .confirmationDialog(
            compressConfirmTitle,
            isPresented: $showCompressConfirmation,
            titleVisibility: .visible
        ) {
            Button("Good Quality (720p) — Save more space") {
                if let video = videoToCompress {
                    startCompression(video: video, quality: .medium)
                }
                videoToCompress = nil
            }
            Button("High Quality (1080p) — Keep clarity") {
                if let video = videoToCompress {
                    startCompression(video: video, quality: .high)
                }
                videoToCompress = nil
            }
            Button("Cancel", role: .cancel) {
                videoToCompress = nil
            }
        } message: {
            if let video = videoToCompress {
                let mediumSave = VideoCompressionService.shared.estimateSavings(for: video, quality: .medium)
                let highSave = VideoCompressionService.shared.estimateSavings(for: video, quality: .high)
                Text("Original: \(video.formattedSize)\n720p saves ~\(ByteCountFormatter.string(fromByteCount: mediumSave, countStyle: .file))\n1080p saves ~\(ByteCountFormatter.string(fromByteCount: highSave, countStyle: .file))\n\nThe compressed video replaces the original.")
            }
        }
    }

    private var compressConfirmTitle: String {
        if let video = videoToCompress {
            return "Compress \(video.formattedSize) Video?"
        }
        return "Compress Video?"
    }

    private var videoList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                HStack {
                    Text("\(viewModel.videos.count) videos")
                        .pebbleBody()
                    Spacer()
                    Text("Sorted by size")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.pebbleStone)
                }
                .padding(.horizontal, PebbleLayout.screenPadding)

                ForEach(viewModel.videos, id: \.id) { video in
                    VideoCardWithCompress(
                        video: video,
                        isCompressing: compressingVideoId == video.id,
                        compressionProgress: compressingVideoId == video.id ? compressionProgress : 0,
                        onToggle: {
                            viewModel.toggleById(video.id)
                        },
                        onCompress: {
                            videoToCompress = video
                            showCompressConfirmation = true
                        },
                        onCancelCompress: {
                            cancelCompression()
                        }
                    )
                    .padding(.horizontal, PebbleLayout.screenPadding)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private func startCompression(video: VideoItem, quality: VideoCompressionService.CompressionQuality) {
        guard compressingVideoId == nil else { return }
        compressingVideoId = video.id
        compressionProgress = 0

        compressionTask = Task {
            do {
                let saved = try await VideoCompressionService.shared.compressVideo(
                    asset: video.asset,
                    quality: quality
                ) { progress in
                    Task { @MainActor in
                        compressionProgress = progress
                    }
                }
                lastCompressionSaved = saved
                compressionError = nil
            } catch is CancellationError {
                compressionError = "Compression was cancelled."
                lastCompressionSaved = 0
            } catch {
                compressionError = error.localizedDescription
                lastCompressionSaved = 0
            }
            compressingVideoId = nil
            compressionProgress = 0
            compressionTask = nil
            showCompressionResult = true
        }
    }

    private func cancelCompression() {
        compressionTask?.cancel()
        compressionTask = nil
        compressingVideoId = nil
        compressionProgress = 0
    }
}

struct VideoCardWithCompress: View {
    let video: VideoItem
    let isCompressing: Bool
    let compressionProgress: Double
    let onToggle: () -> Void
    let onCompress: () -> Void
    let onCancelCompress: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 14) {
                    ZStack(alignment: .bottomTrailing) {
                        AssetThumbnailView(asset: video.asset, size: CGSize(width: 180, height: 180))
                            .frame(width: 90, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text(video.formattedDuration)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.black.opacity(0.65))
                            )
                            .padding(4)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.formattedSize)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(.pebbleObsidian)

                        Text(video.formattedDate)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.pebbleStone)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(video.isSelected ? Color.pebbleViolet : Color.clear)
                            .overlay(
                                Circle()
                                    .stroke(video.isSelected ? Color.clear : Color.pebbleStone.opacity(0.3), lineWidth: 1.5)
                            )
                            .frame(width: 26, height: 26)

                        if video.isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isCompressing {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.pebbleViolet)
                        Text("Compressing…")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundColor(.pebbleViolet)
                        Spacer()
                        Text("\(Int(compressionProgress * 100))%")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundColor(.pebbleStone)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.pebbleViolet.opacity(0.15))
                                .frame(height: 5)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.pebbleViolet, .pebbleViolet.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geo.size.width * compressionProgress, 8), height: 5)
                                .animation(.linear(duration: 0.2), value: compressionProgress)
                        }
                    }
                    .frame(height: 5)

                    Button(action: onCancelCompress) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Cancel")
                                .font(.system(.caption2, design: .rounded).weight(.semibold))
                        }
                        .foregroundColor(.pebbleCoral)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.pebbleCoral.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            } else {
                Button(action: onCompress) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Compress")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    .foregroundColor(.pebbleViolet)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.pebbleViolet.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            isCompressing ? Color.pebbleViolet.opacity(0.3) :
                            video.isSelected ? Color.pebbleViolet.opacity(0.3) : Color.pebbleCardBorder,
                            lineWidth: (video.isSelected || isCompressing) ? 2 : 1
                        )
                )
                .shadow(color: .pebbleCardShadow, radius: video.isSelected ? 8 : 12, x: 0, y: 4)
        )
    }
}
