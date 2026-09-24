import SwiftUI
import Contacts

struct DuplicateContactsView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @ObservedObject var permissionService: PermissionService
    let initialGroups: [DuplicateContactGroup]
    @Environment(\.dismiss) private var dismiss
    @State private var showMergeConfirm = false
    @State private var selectedGroupIndex: Int?

    var body: some View {
        Group {
            if !permissionService.isContactAuthorized {
                if permissionService.isContactDenied {
                    EmptyStateView(
                        title: "Contact Access Denied",
                        message: "Pebble needs access to your contacts to find duplicates. Please enable access in Settings.",
                        icon: "person.crop.circle.badge.xmark"
                    )
                } else {
                    PermissionPromptView(type: .contacts) {
                        Task {
                            _ = await permissionService.requestContactAccess()
                            if permissionService.isContactAuthorized {
                                await viewModel.scanForDuplicates()
                            }
                        }
                    }
                }
            } else if viewModel.isLoading {
                loadingView
            } else if viewModel.duplicateGroups.isEmpty {
                EmptyStateView(
                    title: "No Duplicates Found",
                    message: "Your contacts look clean! No duplicates were detected.",
                    icon: "person.crop.circle.badge.checkmark",
                    showSettingsButton: false
                )
            } else {
                duplicatesList
            }
        }
        .navigationTitle("Duplicate Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !initialGroups.isEmpty {
                viewModel.loadGroups(from: initialGroups)
            } else if permissionService.isContactAuthorized {
                Task { await viewModel.scanForDuplicates() }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.pebbleSage)
                .scaleEffect(1.5)

            Text("Scanning contacts...")
                .pebbleBody()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pebbleCanvas.ignoresSafeArea())
    }

    private var duplicatesList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 16) {
                HStack {
                    Text("\(viewModel.unresolvedCount) duplicate groups")
                        .pebbleBody()
                    Spacer()
                }
                .padding(.horizontal, PebbleLayout.screenPadding)

                ForEach(Array(viewModel.duplicateGroups.enumerated()), id: \.element.id) { index, group in
                    if !group.isResolved {
                        ContactGroupCard(
                            group: group,
                            onMerge: {
                                selectedGroupIndex = index
                                showMergeConfirm = true
                            },
                            onDelete: { contactIndex in
                                Task {
                                    try? await viewModel.deleteFromGroup(at: index, contactIndex: contactIndex)
                                }
                            }
                        )
                        .padding(.horizontal, PebbleLayout.screenPadding)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.pebbleCanvas.ignoresSafeArea())
        .confirmationDialog(
            "Merge Contacts",
            isPresented: $showMergeConfirm,
            titleVisibility: .visible
        ) {
            Button("Smart Merge") {
                if let index = selectedGroupIndex {
                    Task {
                        try? await viewModel.mergeGroup(at: index)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will combine all unique phone numbers and emails into one contact and remove the duplicates.")
        }
    }
}

struct ContactGroupCard: View {
    let group: DuplicateContactGroup
    let onMerge: () -> Void
    let onDelete: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.pebbleCreamApricot)
                        .frame(width: 40, height: 40)

                    Text(group.displayName.prefix(1).uppercased())
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.pebbleOchre)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.displayName)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.pebbleObsidian)

                    HStack(spacing: 4) {
                        Image(systemName: group.matchReason == .sameName ? "textformat" :
                                group.matchReason == .samePhone ? "phone.fill" : "envelope.fill")
                            .font(.system(size: 10))
                        Text(group.matchReason.rawValue)
                            .font(.system(.caption2, design: .rounded))
                    }
                    .foregroundColor(.pebbleStone)
                }

                Spacer()

                Text("\(group.contactCount) contacts")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.pebbleOchre)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.pebbleCreamApricot)
                    )
            }

            Divider()
                .background(Color.pebbleCardBorder)

            ForEach(Array(group.contacts.enumerated()), id: \.element.identifier) { index, contact in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(contact.fullName)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundColor(.pebbleObsidian)

                        if let phone = contact.primaryPhone {
                            Text(phone)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.pebbleSlate)
                        }

                        if let email = contact.primaryEmail {
                            Text(email)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.pebbleSlate)
                        }
                    }

                    Spacer()

                    if index == group.primaryIndex {
                        Text("Primary")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.pebbleSage)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.pebbleSage.opacity(0.1))
                            )
                    } else {
                        Button {
                            onDelete(index)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundColor(.pebbleCoral)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.pebbleCoral.opacity(0.1))
                                )
                        }
                    }
                }
            }

            if group.contacts.count >= 2 {
                Button(action: onMerge) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.merge")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Smart Merge")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    .foregroundColor(.pebbleSage)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.pebbleSage.opacity(0.08))
                    )
                }
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
}
