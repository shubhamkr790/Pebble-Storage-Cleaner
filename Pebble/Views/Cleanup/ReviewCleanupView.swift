import SwiftUI
import Photos

struct ReviewCleanupView: View {
    let plan: CleanupPlan
    let estimatedSize: Int64
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @State private var showDestructiveConfirm = false

    private var allAssets: [PHAsset] {
        plan.photoAssets + plan.screenshotAssets + plan.videoAssets
    }

    private var formattedSize: String {
        let size = estimatedSize > 0 ? estimatedSize : Int64(max(plan.totalAssets, 1) * 2_500_000)
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pebbleCanvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            VStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.pebbleCoral.opacity(0.12), .pebbleOchre.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 72, height: 72)

                                    Image(systemName: "trash.slash.circle.fill")
                                        .font(.system(size: 36))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundColor(.pebbleCoral)
                                }

                                Text("Review & Clean")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundColor(.pebbleObsidian)

                                Text("Confirm the items you'd like to remove.")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.pebbleStone)
                            }
                            .padding(.top, 20)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Space to Free")
                                        .font(.system(.caption, design: .rounded).weight(.medium))
                                        .foregroundColor(.pebbleStone)
                                    Text(formattedSize)
                                        .font(.system(.title2, design: .rounded).weight(.bold))
                                        .foregroundColor(.pebbleSage)
                                }

                                Spacer()

                                ZStack {
                                    Circle()
                                        .fill(Color.pebbleSage.opacity(0.1))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "arrow.up.bin.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.pebbleSage)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: PebbleLayout.cardRadius, style: .continuous)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: PebbleLayout.cardRadius, style: .continuous)
                                            .stroke(Color.pebbleSage.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: .pebbleCardShadow, radius: 12, x: 0, y: 4)
                            )
                            .padding(.horizontal, PebbleLayout.screenPadding)

                            VStack(spacing: 0) {
                                ForEach(Array(plan.summaryItems.enumerated()), id: \.element.id) { index, item in
                                    HStack(spacing: 12) {
                                        PebbleCategoryBadge(category: item.type.category, size: 38)

                                        Text(item.type.rawValue)
                                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                                            .foregroundColor(.pebbleObsidian)

                                        Spacer()

                                        Text("\(item.count) items")
                                            .font(.system(.caption, design: .rounded).weight(.semibold))
                                            .foregroundColor(.pebbleStone)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.pebbleCanvas)
                                            .clipShape(Capsule())
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)

                                    if index < plan.summaryItems.count - 1 {
                                        Divider()
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: PebbleLayout.cardRadius, style: .continuous)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: PebbleLayout.cardRadius, style: .continuous)
                                            .stroke(Color.pebbleCardBorder, lineWidth: 1)
                                    )
                                    .shadow(color: .pebbleCardShadow, radius: 12, x: 0, y: 4)
                            )
                            .padding(.horizontal, PebbleLayout.screenPadding)

                            if !allAssets.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Items to Remove")
                                        .font(.system(.caption, design: .rounded).weight(.semibold))
                                        .foregroundColor(.pebbleStone)
                                        .textCase(.uppercase)
                                        .padding(.horizontal, PebbleLayout.screenPadding)

                                    LazyVGrid(columns: columns, spacing: 3) {
                                        ForEach(allAssets.prefix(20), id: \.localIdentifier) { asset in
                                            AssetThumbnailView(asset: asset, size: CGSize(width: 180, height: 180))
                                                .aspectRatio(1, contentMode: .fill)
                                                .clipped()
                                                .overlay(
                                                    Color.pebbleCoral.opacity(0.08)
                                                )
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .padding(.horizontal, PebbleLayout.screenPadding)

                                    if allAssets.count > 20 {
                                        Text("+ \(allAssets.count - 20) more items")
                                            .font(.system(.caption, design: .rounded).weight(.medium))
                                            .foregroundColor(.pebbleStone)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }

                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.pebbleCobalt.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "shield.checkered")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.pebbleCobalt)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Safe & Recoverable")
                                        .font(.system(.caption, design: .rounded).weight(.bold))
                                        .foregroundColor(.pebbleObsidian)
                                    Text("Items move to **Recently Deleted** and can be recovered within **30 days**.")
                                        .font(.system(.caption2, design: .rounded))
                                        .foregroundColor(.pebbleSlate)
                                        .lineSpacing(2)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.pebbleGentleSky.opacity(0.4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.pebbleCobalt.opacity(0.12), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, PebbleLayout.screenPadding)

                            Spacer().frame(height: 8)
                        }
                    }

                    VStack(spacing: 10) {
                        PebblePillButton("Delete \(plan.totalItems) Items · \(formattedSize)", icon: "trash.fill", style: .destructive) {
                            showDestructiveConfirm = true
                        }

                        Button {
                            onCancel()
                        } label: {
                            Text("Cancel")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundColor(.pebbleStone)
                                .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal, PebbleLayout.screenPadding)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea(.all, edges: .bottom)
                    )
                }
            }
            .confirmationDialog(
                "Confirm Cleanup",
                isPresented: $showDestructiveConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete \(plan.totalItems) Items", role: .destructive) {
                    onConfirm()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will move \(plan.totalAssets) photos/videos to Recently Deleted. You can recover them within 30 days.")
            }
        }
    }
}

struct CleanupCompleteView: View {
    let result: CleanupResult
    let onDone: () -> Void
    @State private var showConfetti = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                if showConfetti {
                    ForEach(0..<12, id: \.self) { i in
                        Circle()
                            .fill(confettiColor(for: i))
                            .frame(width: CGFloat.random(in: 8...14))
                            .offset(confettiOffset(for: i))
                            .opacity(showConfetti ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.5).delay(Double(i) * 0.05),
                                value: showConfetti
                            )
                    }
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pebbleSage, .pebbleMint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(checkmarkScale)

                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(checkmarkScale)
            }

            VStack(spacing: 12) {
                Text("All Clean! 🎉")
                    .pebbleTitle()

                Text("You freed up \(result.formattedFreed) of storage.")
                    .pebbleBody()
                    .multilineTextAlignment(.center)
            }
            .opacity(textOpacity)

            VStack(spacing: 8) {
                if result.deletedPhotoCount > 0 {
                    statRow(icon: "photo.fill", text: "\(result.deletedPhotoCount) photos removed", color: .pebbleCoral)
                }
                if result.deletedVideoCount > 0 {
                    statRow(icon: "film.fill", text: "\(result.deletedVideoCount) videos removed", color: .pebbleViolet)
                }
                if result.deletedContactCount > 0 {
                    statRow(icon: "person.fill", text: "\(result.deletedContactCount) contacts cleaned", color: .pebbleOchre)
                }
                if result.mergedContactCount > 0 {
                    statRow(icon: "arrow.triangle.merge", text: "\(result.mergedContactCount) contacts merged", color: .pebbleSage)
                }
            }
            .opacity(textOpacity)
            .padding(.horizontal, 40)

            Spacer()

            PebblePillButton("Done", icon: "checkmark") {
                onDone()
            }
            .opacity(textOpacity)

            Spacer()
                .frame(height: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pebbleCanvas.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                checkmarkScale = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                textOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }

    private func statRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.pebbleSlate)

            Spacer()
        }
    }

    private func confettiColor(for index: Int) -> Color {
        let colors: [Color] = [.pebbleSage, .pebbleMint, .pebbleCoral, .pebbleCobalt, .pebbleViolet, .pebbleOchre]
        return colors[index % colors.count]
    }

    private func confettiOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 12.0) * .pi / 180.0
        let radius: CGFloat = showConfetti ? 120 : 0
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }
}
