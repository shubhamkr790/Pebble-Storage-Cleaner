import Foundation
import Photos
import Contacts
import SwiftUI

@MainActor
class PermissionService: ObservableObject {
    static let shared = PermissionService()

    @Published var photoAuthStatus: PHAuthorizationStatus = .notDetermined
    @Published var contactAuthStatus: CNAuthorizationStatus = .notDetermined

    var isPhotoAuthorized: Bool {
        photoAuthStatus == .authorized
    }

    var isPhotoLimited: Bool {
        photoAuthStatus == .limited
    }

    var isPhotoDenied: Bool {
        photoAuthStatus == .denied || photoAuthStatus == .restricted
    }

    var isContactAuthorized: Bool {
        contactAuthStatus == .authorized
    }

    var isContactDenied: Bool {
        contactAuthStatus == .denied || contactAuthStatus == .restricted
    }

    init() {
        refreshStatuses()
    }

    func refreshStatuses() {
        photoAuthStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        contactAuthStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestPhotoAccess() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.photoAuthStatus = status
        }
        return status
    }

    func requestContactAccess() async -> Bool {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                self.contactAuthStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            await MainActor.run {
                self.contactAuthStatus = .denied
            }
            return false
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
