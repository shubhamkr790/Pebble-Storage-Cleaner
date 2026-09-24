import SwiftUI

struct FloatingDockBar: View {
    @Binding var selectedTab: DockTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DockTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                            .symbolRenderingMode(.hierarchical)

                        Text(tab.label)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(selectedTab == tab ? .pebbleSage : .pebbleStone)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == tab ?
                        Capsule(style: .continuous)
                            .fill(Color.pebbleSage.opacity(0.1))
                            .padding(.horizontal, 8)
                        : nil
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.pebbleCardBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 8)
        )
        .padding(.horizontal, 24)
    }
}

enum DockTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case photos = "Photos"
    case videos = "Videos"
    case contacts = "Contacts"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .photos: return "photo.stack.fill"
        case .videos: return "film.stack.fill"
        case .contacts: return "person.2.fill"
        }
    }

    var label: String { rawValue }
}
