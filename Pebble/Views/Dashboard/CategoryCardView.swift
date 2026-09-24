import SwiftUI

struct CategoryCardView: View {
    let result: CategoryScanResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                PebbleCategoryBadge(category: result.category, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.category.rawValue)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.pebbleObsidian)

                    Text(result.subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.pebbleStone)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 8) {
                    if result.isScanned && result.freeableBytes > 0 {
                        Text(result.formattedFreeable)
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(result.category.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(result.category.backgroundColor)
                            )
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.pebbleStone.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: PebbleLayout.cardRadius, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: PebbleLayout.cardRadius, style: .continuous)
                            .stroke(Color.pebbleCardBorder, lineWidth: 1)
                    )
                    .shadow(color: .pebbleCardShadow, radius: 16, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}
