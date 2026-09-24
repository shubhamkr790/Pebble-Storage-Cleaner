import Foundation
import Contacts

class ContactScanService {
    static let shared = ContactScanService()
    private let store = CNContactStore()

    private let keysToFetch: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactIdentifierKey as CNKeyDescriptor
    ]

    func findDuplicates() async -> [DuplicateContactGroup] {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                var allContacts: [CNContact] = []

                let request = CNContactFetchRequest(keysToFetch: self.keysToFetch)
                request.sortOrder = .givenName

                do {
                    try self.store.enumerateContacts(with: request) { contact, _ in
                        allContacts.append(contact)
                    }
                } catch {
                    print("ContactScanService fetch error: \(error)")
                    continuation.resume(returning: [])
                    return
                }

                var groups: [DuplicateContactGroup] = []
                var processedIdentifiers = Set<String>()

                let nameGroups = self.groupByName(allContacts)
                for contacts in nameGroups.values {
                    if contacts.count >= 2 {
                        let ids = contacts.map { $0.identifier }
                        if !ids.allSatisfy({ processedIdentifiers.contains($0) }) {
                            ids.forEach { processedIdentifiers.insert($0) }
                            groups.append(DuplicateContactGroup(
                                matchReason: .sameName,
                                contacts: contacts
                            ))
                        }
                    }
                }

                let phoneGroups = self.groupByPhone(allContacts, excluding: processedIdentifiers)
                for contacts in phoneGroups.values {
                    if contacts.count >= 2 {
                        let ids = contacts.map { $0.identifier }
                        if !ids.allSatisfy({ processedIdentifiers.contains($0) }) {
                            ids.forEach { processedIdentifiers.insert($0) }
                            groups.append(DuplicateContactGroup(
                                matchReason: .samePhone,
                                contacts: contacts
                            ))
                        }
                    }
                }

                let emailGroups = self.groupByEmail(allContacts, excluding: processedIdentifiers)
                for contacts in emailGroups.values {
                    if contacts.count >= 2 {
                        let ids = contacts.map { $0.identifier }
                        ids.forEach { processedIdentifiers.insert($0) }
                        groups.append(DuplicateContactGroup(
                            matchReason: .sameEmail,
                            contacts: contacts
                        ))
                    }
                }

                continuation.resume(returning: groups)
            }
        }
    }

    private func groupByName(_ contacts: [CNContact]) -> [String: [CNContact]] {
        var groups: [String: [CNContact]] = [:]
        for contact in contacts {
            let name = "\(contact.givenName) \(contact.familyName)"
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            guard !name.isEmpty, name != " " else { continue }
            groups[name, default: []].append(contact)
        }
        return groups
    }

    private func groupByPhone(_ contacts: [CNContact], excluding: Set<String>) -> [String: [CNContact]] {
        var groups: [String: [CNContact]] = [:]
        for contact in contacts {
            guard !excluding.contains(contact.identifier) else { continue }
            for phone in contact.phoneNumbers {
                let normalized = self.normalizePhone(phone.value.stringValue)
                guard !normalized.isEmpty else { continue }
                groups[normalized, default: []].append(contact)
            }
        }
        return groups
    }

    private func groupByEmail(_ contacts: [CNContact], excluding: Set<String>) -> [String: [CNContact]] {
        var groups: [String: [CNContact]] = [:]
        for contact in contacts {
            guard !excluding.contains(contact.identifier) else { continue }
            for email in contact.emailAddresses {
                let normalized = (email.value as String).lowercased().trimmingCharacters(in: .whitespaces)
                guard !normalized.isEmpty else { continue }
                groups[normalized, default: []].append(contact)
            }
        }
        return groups
    }

    private func normalizePhone(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }
        if digits.count >= 10 {
            return String(digits.suffix(10))
        }
        return digits
    }

    func mergeContacts(primary: CNContact, duplicates: [CNContact]) async throws {
        let mutablePrimary = try store.unifiedContact(withIdentifier: primary.identifier, keysToFetch: keysToFetch)
        let mutableCopy = mutablePrimary.mutableCopy() as! CNMutableContact

        var existingPhones = Set(mutableCopy.phoneNumbers.map { normalizePhone($0.value.stringValue) })
        for dup in duplicates {
            for phone in dup.phoneNumbers {
                let norm = normalizePhone(phone.value.stringValue)
                if !existingPhones.contains(norm) {
                    mutableCopy.phoneNumbers.append(phone)
                    existingPhones.insert(norm)
                }
            }
        }

        var existingEmails = Set(mutableCopy.emailAddresses.map { ($0.value as String).lowercased() })
        for dup in duplicates {
            for email in dup.emailAddresses {
                let norm = (email.value as String).lowercased()
                if !existingEmails.contains(norm) {
                    mutableCopy.emailAddresses.append(email)
                    existingEmails.insert(norm)
                }
            }
        }

        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableCopy)

        for dup in duplicates {
            let mutableDup = dup.mutableCopy() as! CNMutableContact
            saveRequest.delete(mutableDup)
        }

        try store.execute(saveRequest)
    }

    func deleteContacts(_ contacts: [CNContact]) async throws {
        let saveRequest = CNSaveRequest()
        for contact in contacts {
            let mutableContact = contact.mutableCopy() as! CNMutableContact
            saveRequest.delete(mutableContact)
        }
        try store.execute(saveRequest)
    }
}
