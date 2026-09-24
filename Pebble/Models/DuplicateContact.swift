import Foundation
import Contacts

struct DuplicateContactGroup: Identifiable {
    let id = UUID()
    let matchReason: MatchReason
    var contacts: [CNContact]
    var primaryIndex: Int = 0
    var isResolved: Bool = false

    enum MatchReason: String {
        case sameName = "Same Name"
        case samePhone = "Same Phone Number"
        case sameEmail = "Same Email Address"
    }

    var primaryContact: CNContact {
        contacts[primaryIndex]
    }

    var duplicateContacts: [CNContact] {
        contacts.enumerated()
            .filter { $0.offset != primaryIndex }
            .map { $0.element }
    }

    var displayName: String {
        let c = primaryContact
        let name = "\(c.givenName) \(c.familyName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "No Name" : name
    }

    var contactCount: Int {
        contacts.count
    }
}

extension CNContact {
    var fullName: String {
        let name = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "No Name" : name
    }

    var primaryPhone: String? {
        phoneNumbers.first?.value.stringValue
    }

    var primaryEmail: String? {
        emailAddresses.first?.value as String?
    }

    var allPhoneNumbers: [String] {
        phoneNumbers.map { $0.value.stringValue }
    }

    var allEmails: [String] {
        emailAddresses.map { $0.value as String }
    }
}
