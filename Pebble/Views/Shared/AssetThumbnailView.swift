import SwiftUI
import Photos

struct AssetThumbnailView: View {
    let asset: PHAsset
    var size: CGSize = CGSize(width: 200, height: 200)
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.pebbleCanvas)
                    .overlay(
                        ProgressView()
                            .tint(.pebbleStone)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: asset.localIdentifier) { _, _ in
            self.image = nil
            loadImage()
        }
    }

    private func loadImage() {
        PhotoScanService.shared.loadThumbnail(for: asset, size: size) { loaded in
            DispatchQueue.main.async {
                self.image = loaded
            }
        }
    }
}

struct FullImageView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .onAppear {
            loadFullImage()
        }
        .onChange(of: asset.localIdentifier) { _, _ in
            self.image = nil
            loadFullImage()
        }
    }

    private func loadFullImage() {
        PhotoScanService.shared.loadFullImage(for: asset) { loaded in
            DispatchQueue.main.async {
                self.image = loaded
            }
        }
    }
}
