import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var isCompleted = false

    let slides: [OnboardingSlide] = [
        OnboardingSlide(
            title: "Declutter with ease",
            subtitle: "Free up space without the stress of losing precious moments.",
            iconName: "sparkles",
            gradientColors: [.pebbleMint.opacity(0.3), .pebbleSage.opacity(0.15)]
        ),
        OnboardingSlide(
            title: "Smart & Safe Selection",
            subtitle: "Pebble highlights the best shots and groups the clutter for you.",
            iconName: "wand.and.stars",
            gradientColors: [.pebbleCobalt.opacity(0.2), .pebbleViolet.opacity(0.15)]
        ),
        OnboardingSlide(
            title: "100% Private & Local",
            subtitle: "Your photos and contacts never leave this device.",
            iconName: "lock.shield.fill",
            gradientColors: [.pebbleSage.opacity(0.2), .pebbleMint.opacity(0.3)]
        )
    ]

    var isLastSlide: Bool {
        currentPage == slides.count - 1
    }

    func nextPage() {
        if currentPage < slides.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                currentPage += 1
            }
        }
    }

    func skip() {
        complete()
    }

    func complete() {
        isCompleted = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let gradientColors: [Color]
}
