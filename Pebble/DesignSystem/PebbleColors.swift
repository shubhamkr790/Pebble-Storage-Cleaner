import SwiftUI

extension Color {
    static let pebbleCanvas = Color(hex: "F8FAF7")
    static let pebblePureCanvas = Color.white

    static let pebbleSage = Color(hex: "2D6A4F")
    static let pebbleMint = Color(hex: "40916C")

    static let pebbleObsidian = Color(hex: "151916")
    static let pebbleSlate = Color(hex: "525A55")
    static let pebbleStone = Color(hex: "8C968F")

    static let pebbleCardBorder = Color.black.opacity(0.04)
    static let pebbleCardShadow = Color.black.opacity(0.05)

    static let pebbleBlushRose = Color(hex: "FFEBEB")
    static let pebbleGentleSky = Color(hex: "EBF3FF")
    static let pebbleWarmLavender = Color(hex: "F3E8FF")
    static let pebbleCreamApricot = Color(hex: "FFF4E6")

    static let pebbleCoral = Color(hex: "E05757")
    static let pebbleCobalt = Color(hex: "3B82F6")
    static let pebbleViolet = Color(hex: "8B5CF6")
    static let pebbleOchre = Color(hex: "E67E22")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum PebbleCategory: String, CaseIterable, Identifiable {
    case similarPhotos = "Similar Photos"
    case screenshots = "Screenshots"
    case largeVideos = "Large Videos"
    case duplicateContacts = "Duplicate Contacts"
    case blurryPhotos = "Blurry Photos"

    var id: String { rawValue }

    var backgroundColor: Color {
        switch self {
        case .similarPhotos: return .pebbleBlushRose
        case .screenshots: return .pebbleGentleSky
        case .largeVideos: return .pebbleWarmLavender
        case .duplicateContacts: return .pebbleCreamApricot
        case .blurryPhotos: return Color(hex: "FFF8E1")
        }
    }

    var accentColor: Color {
        switch self {
        case .similarPhotos: return .pebbleCoral
        case .screenshots: return .pebbleCobalt
        case .largeVideos: return .pebbleViolet
        case .duplicateContacts: return .pebbleOchre
        case .blurryPhotos: return Color(hex: "F59E0B")
        }
    }

    var iconName: String {
        switch self {
        case .similarPhotos: return "photo.on.rectangle.angled"
        case .screenshots: return "rectangle.portrait.on.rectangle.portrait"
        case .largeVideos: return "film.stack"
        case .duplicateContacts: return "person.2.fill"
        case .blurryPhotos: return "camera.metering.unknown"
        }
    }

    var subtitle: String {
        switch self {
        case .similarPhotos: return "Find duplicate & similar shots"
        case .screenshots: return "Review & clean screenshots"
        case .largeVideos: return "Remove space-hogging videos"
        case .duplicateContacts: return "Merge duplicate entries"
        case .blurryPhotos: return "Find out-of-focus shots"
        }
    }
}
