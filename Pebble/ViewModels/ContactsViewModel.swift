import SwiftUI
import Contacts

@MainActor
class ContactsViewModel: ObservableObject {
    @Published var duplicateGroups: [DuplicateContactGroup] = []
    @Published var isLoading = false
    @Published var isProcessing = false

    var unresolvedCount: Int {
        duplicateGroups.filter { !$0.isResolved }.count
    }

    func loadGroups(from cached: [DuplicateContactGroup]) {
        self.duplicateGroups = cached
    }

    func scanForDuplicates() async {
        isLoading = true
        duplicateGroups = await ContactScanService.shared.findDuplicates()
        isLoading = false
    }

    func mergeGroup(at index: Int) async throws {
        guard index < duplicateGroups.count else { return }
        isProcessing = true
        defer { isProcessing = false }

        let group = duplicateGroups[index]
        try await ContactScanService.shared.mergeContacts(
            primary: group.primaryContact,
            duplicates: group.duplicateContacts
        )
        duplicateGroups[index].isResolved = true
    }

    func deleteFromGroup(at index: Int, contactIndex: Int) async throws {
        guard index < duplicateGroups.count else { return }
        isProcessing = true
        defer { isProcessing = false }

        let contact = duplicateGroups[index].contacts[contactIndex]
        try await ContactScanService.shared.deleteContacts([contact])

        duplicateGroups[index].contacts.remove(at: contactIndex)
        if duplicateGroups[index].contacts.count <= 1 {
            duplicateGroups[index].isResolved = true
        }
    }
}
