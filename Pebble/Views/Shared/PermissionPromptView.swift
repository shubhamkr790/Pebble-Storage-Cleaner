import SwiftUI

struct PermissionPromptView: View {
    let type: PermissionType
    let onAllow: () -> Void

    enum PermissionType {
        case photos
        case contacts

        var title: String {
            switch self {
            case .photos: return "Access Your Photos"
            case .contacts: return "Access Your Contacts"
            }
        }

        var subtitle: String {
            switch self {
            case .photos: return "Pebble scans your photo library locally on this device to find duplicates, similar shots, and screenshots you can safely clean up."
            case .contacts: return "Pebble checks your contacts locally to find duplicate entries that can be merged or removed."
            }
        }

        var icon: String {
            switch self {
            case .photos: return "photo.on.rectangle.angled"
            case .contacts: return "person.crop.rectangle.stack.fill"
            }
        }

        var privacyNote: String {
            switch self {
            case .photos: return "Your photos never leave this device. Zero cloud. Zero tracking."
            case .contacts: return "Your contacts stay private. Everything runs on-device."
            }
        }

        var buttonTitle: String {
            switch self {
            case .photos: return "Allow Photo Access"
            case .contacts: return "Allow Contact Access"
            }
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pebbleSage.opacity(0.15), .pebbleMint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: type.icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.pebbleSage)
            }

            VStack(spacing: 12) {
                Text(type.title)
                    .pebbleTitle2()
                    .multilineTextAlignment(.center)

                Text(type.subtitle)
                    .pebbleBody()
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.pebbleSage)

                Text(type.privacyNote)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.pebbleStone)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.pebbleSage.opacity(0.06))
            )

            PebblePillButton(type.buttonTitle, icon: "checkmark.shield.fill") {
                onAllow()
            }

            Spacer()
                .frame(height: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pebbleCanvas.ignoresSafeArea())
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    var showSettingsButton: Bool = true

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.pebbleCoral.opacity(0.1))
                    .frame(width: 90, height: 90)

                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.pebbleCoral)
            }

            VStack(spacing: 12) {
                Text(title)
                    .pebbleTitle3()
                    .multilineTextAlignment(.center)

                Text(message)
                    .pebbleBody()
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)

            if showSettingsButton {
                PebblePillButton("Open Settings", icon: "gear") {
                    PermissionService.shared.openSettings()
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pebbleCanvas.ignoresSafeArea())
    }
}

struct LimitedAccessBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.pebbleOchre)

            VStack(alignment: .leading, spacing: 2) {
                Text("Limited Access")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(.pebbleObsidian)

                Text("Only selected photos are visible. Grant full access for a complete scan.")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.pebbleSlate)
            }

            Spacer()

            Button {
                PermissionService.shared.openSettings()
            } label: {
                Text("Settings")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(.pebbleSage)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.pebbleSage.opacity(0.1))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.pebbleCreamApricot.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.pebbleOchre.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, PebbleLayout.screenPadding)
    }
}
