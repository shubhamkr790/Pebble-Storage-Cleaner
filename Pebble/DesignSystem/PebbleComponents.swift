import SwiftUI

enum PebbleLayout {
    static let screenPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 20
    static let cardRadius: CGFloat = 26
    static let modalRadius: CGFloat = 30
    static let badgeRadius: CGFloat = 16
    static let capsuleRadius: CGFloat = 999
}

struct PebbleCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
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
}

struct PebblePillButton: View {
    let title: String
    let icon: String?
    let style: PillButtonStyle
    let action: () -> Void

    enum PillButtonStyle {
        case primary
        case secondary
        case destructive
    }

    init(_ title: String, icon: String? = nil, style: PillButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule(style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: some ShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(LinearGradient(colors: [.pebbleSage, .pebbleMint], startPoint: .leading, endPoint: .trailing))
        case .secondary:
            return AnyShapeStyle(Color.clear)
        case .destructive:
            return AnyShapeStyle(Color.pebbleCoral)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .pebbleSage
        case .destructive: return .white
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary: return .pebbleSage.opacity(0.3)
        default: return .clear
        }
    }
}

struct PebbleCategoryBadge: View {
    let category: PebbleCategory
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PebbleLayout.badgeRadius, style: .continuous)
                .fill(category.backgroundColor)
                .frame(width: size, height: size)

            Image(systemName: category.iconName)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(category.accentColor)
        }
    }
}

struct PebbleSelectionOverlay: View {
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if isSelected {
                Color.pebbleSage.opacity(0.15)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.pebbleSage, lineWidth: 2.5)
            }

            Circle()
                .fill(isSelected ? Color.pebbleSage : Color.white.opacity(0.8))
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.clear : Color.pebbleStone.opacity(0.4), lineWidth: 1.5)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isSelected ? 1 : 0)
                )
                .frame(width: 24, height: 24)
                .padding(6)
        }
    }
}

struct BestPickBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 11, weight: .bold))
            Text("Best Pick")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(Color.pebbleSage)
        )
    }
}

struct FloatingActionBar: View {
    let itemCount: Int
    let totalSize: String
    var actionTitle: String = "Review"
    var icon: String = "trash.fill"
    let action: () -> Void

    init(
        itemCount: Int,
        totalSize: String,
        actionTitle: String = "Review",
        icon: String = "trash.fill",
        action: @escaping () -> Void
    ) {
        self.itemCount = itemCount
        self.totalSize = totalSize
        self.actionTitle = actionTitle
        self.icon = icon
        self.action = action
    }

    private var itemText: String {
        itemCount == 1 ? "1 item" : "\(itemCount) items"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pebbleSage.opacity(0.12), .pebbleMint.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.pebbleSage)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(itemText) selected")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.pebbleObsidian)

                if !totalSize.isEmpty {
                    Text(totalSize)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(.pebbleStone)
                }
            }

            Spacer()

            Button(action: action) {
                HStack(spacing: 6) {
                    Text(actionTitle)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.pebbleSage, .pebbleMint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(PebbleFloatingButtonStyle())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: PebbleLayout.cardRadius, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: PebbleLayout.cardRadius, style: .continuous)
                        .stroke(Color.pebbleSage.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.pebbleSage.opacity(0.10), radius: 20, x: 0, y: -6)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: 420)
        .padding(.horizontal, PebbleLayout.screenPadding)
        .padding(.bottom, 8)
    }
}

struct PebbleFloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(.pebbleObsidian)
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(.pebbleStone)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.08))
        )
    }
}
