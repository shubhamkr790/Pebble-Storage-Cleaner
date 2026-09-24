import SwiftUI
import Photos

struct SwipeReviewView: View {
    @StateObject private var viewModel: SwipeReviewViewModel
    let onComplete: ([PHAsset]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    @State private var cardExiting = false

    private let swipeThreshold: CGFloat = 100

    init(assets: [PHAsset], onComplete: @escaping ([PHAsset]) -> Void) {
        _viewModel = StateObject(wrappedValue: SwipeReviewViewModel(assets: assets))
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            Color.pebbleCanvas.ignoresSafeArea()

            if viewModel.assets.isEmpty {
                emptyStateView
            } else if viewModel.isComplete {
                completionView
            } else {
                VStack(spacing: 16) {
                    topBar

                    progressBar

                    Spacer(minLength: 8)

                    cardStackSection

                    Spacer(minLength: 8)

                    actionButtons

                    if viewModel.currentIndex > 0 {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                viewModel.undo()
                                dragOffset = .zero
                                dragRotation = 0
                                cardExiting = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Undo Previous")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            }
                            .foregroundColor(.pebbleStone)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                    }

                    Spacer().frame(height: 12)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.pebbleStone)
                }
                Spacer()
            }
            .padding(.horizontal, PebbleLayout.screenPadding)
            .padding(.top, 16)

            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundColor(.pebbleSage)

            Text("No Photos to Review")
                .pebbleTitle()

            Text("No photos were queued for swipe review. Scan your library to detect duplicates or screenshots.")
                .pebbleBody()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            PebblePillButton("Close", style: .secondary) {
                dismiss()
            }
            .padding(.horizontal, PebbleLayout.screenPadding)
            .padding(.bottom, 24)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.pebbleStone)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(viewModel.currentIndex + 1) of \(viewModel.assets.count)")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.pebbleObsidian)
                Text("\(viewModel.remaining) remaining")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.pebbleStone)
            }

            Spacer()

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.pebbleSage)
                    Text("\(viewModel.keepList.count)")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(.pebbleSage)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.pebbleSage.opacity(0.12))
                .clipShape(Capsule())

                HStack(spacing: 4) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.pebbleCoral)
                    Text("\(viewModel.deleteList.count)")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(.pebbleCoral)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.pebbleCoral.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, PebbleLayout.screenPadding)
        .padding(.top, 12)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.pebbleSage.opacity(0.15))
                    .frame(height: 5)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.pebbleSage, .pebbleMint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geo.size.width * viewModel.progress, 6), height: 5)
                    .animation(.spring(response: 0.3), value: viewModel.progress)
            }
        }
        .frame(height: 5)
        .padding(.horizontal, PebbleLayout.screenPadding)
    }

    private var cardStackSection: some View {
        ZStack {
            if let nextAsset = viewModel.nextAsset {
                let dragProgress = min(abs(dragOffset.width) / 300.0, 1.0)
                cardItem(for: nextAsset)
                    .scaleEffect(0.92 + (0.08 * dragProgress))
                    .opacity(0.6 + (0.4 * dragProgress))
                    .id("next-\(nextAsset.localIdentifier)")
            }

            if let asset = viewModel.currentAsset {
                cardItem(for: asset)
                    .offset(dragOffset)
                    .rotationEffect(.degrees(dragRotation))
                    .overlay(swipeStampOverlay)
                    .gesture(swipeGesture)
                    .id("current-\(asset.localIdentifier)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    private func cardItem(for asset: PHAsset) -> some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width
            let cardHeight = geo.size.height

            ZStack(alignment: .bottom) {
                AssetThumbnailView(asset: asset, size: CGSize(width: 900, height: 900))
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 120)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatAssetDate(asset))
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(.white)

                        HStack(spacing: 8) {
                            Text("\(asset.pixelWidth) × \(asset.pixelHeight)")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))

                            if let sizeStr = formatAssetSize(asset) {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(sizeStr)
                                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                    }

                    Spacer()

                    Text("#\(viewModel.currentIndex + 1)")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.25))
                        .clipShape(Capsule())
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: PebbleLayout.cardRadius, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }

    private var swipeStampOverlay: some View {
        ZStack {
            if dragOffset.width > 20 {
                VStack {
                    HStack {
                        Spacer()
                        Text("KEEP")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.pebbleSage)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.pebbleSage, lineWidth: 3)
                            )
                            .background(Color.white.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .rotationEffect(.degrees(15))
                            .opacity(min(Double(dragOffset.width) / 120.0, 1.0))
                            .padding(24)
                    }
                    Spacer()
                }
            }

            if dragOffset.width < -20 {
                VStack {
                    HStack {
                        Text("DELETE")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.pebbleCoral)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.pebbleCoral, lineWidth: 3)
                            )
                            .background(Color.white.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .rotationEffect(.degrees(-15))
                            .opacity(min(Double(-dragOffset.width) / 120.0, 1.0))
                            .padding(24)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !cardExiting else { return }
                dragOffset = value.translation
                dragRotation = Double(value.translation.width / 22.0)
            }
            .onEnded { value in
                guard !cardExiting else { return }
                if value.translation.width > swipeThreshold {
                    performSwipe(direction: .keep)
                } else if value.translation.width < -swipeThreshold {
                    performSwipe(direction: .delete)
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                        dragOffset = .zero
                        dragRotation = 0
                    }
                }
            }
    }

    private var actionButtons: some View {
        HStack(spacing: 48) {
            Button {
                performSwipe(direction: .delete)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 68, height: 68)
                        .shadow(color: Color.pebbleCoral.opacity(0.2), radius: 12, x: 0, y: 6)

                    Circle()
                        .stroke(Color.pebbleCoral.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 68, height: 68)

                    Image(systemName: "xmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.pebbleCoral)
                }
            }
            .disabled(cardExiting)
            .scaleEffect(cardExiting ? 0.95 : 1.0)

            Button {
                performSwipe(direction: .keep)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 68, height: 68)
                        .shadow(color: Color.pebbleSage.opacity(0.2), radius: 12, x: 0, y: 6)

                    Circle()
                        .stroke(Color.pebbleSage.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 68, height: 68)

                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.pebbleSage)
                }
            }
            .disabled(cardExiting)
            .scaleEffect(cardExiting ? 0.95 : 1.0)
        }
    }

    private enum SwipeDirection {
        case keep, delete
    }

    private func performSwipe(direction: SwipeDirection) {
        guard !cardExiting, viewModel.currentAsset != nil else { return }
        cardExiting = true

        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()

        let exitX: CGFloat = direction == .keep ? 600 : -600

        withAnimation(.easeOut(duration: 0.28)) {
            dragOffset = CGSize(width: exitX, height: 30)
            dragRotation = Double(exitX / 16.0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            switch direction {
            case .keep:
                viewModel.swipeKeep()
            case .delete:
                viewModel.swipeDelete()
            }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dragOffset = .zero
                dragRotation = 0
                cardExiting = false
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.pebbleSage.opacity(0.12))
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.pebbleSage)
            }

            Text("Review Complete!")
                .pebbleTitle()

            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.pebbleSage)
                    Text("Kept \(viewModel.keepList.count) photos")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.pebbleObsidian)
                }

                HStack(spacing: 8) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.pebbleCoral)
                    Text("Marked \(viewModel.deleteList.count) photos to clean")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.pebbleObsidian)
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)

            Spacer()

            VStack(spacing: 12) {
                if !viewModel.deleteList.isEmpty {
                    PebblePillButton("Review & Clean \(viewModel.deleteList.count) Items", icon: "trash.fill", style: .destructive) {
                        onComplete(viewModel.deleteList)
                    }
                }

                PebblePillButton("Done", style: .secondary) {
                    dismiss()
                }
            }
            .padding(.horizontal, PebbleLayout.screenPadding)
            .padding(.bottom, 24)
        }
    }

    private func formatAssetDate(_ asset: PHAsset) -> String {
        guard let date = asset.creationDate else { return "Photo" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatAssetSize(_ asset: PHAsset) -> String? {
        let resources = PHAssetResource.assetResources(for: asset)
        if let res = resources.first, let size = res.value(forKey: "fileSize") as? Int64 {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        return nil
    }
}
