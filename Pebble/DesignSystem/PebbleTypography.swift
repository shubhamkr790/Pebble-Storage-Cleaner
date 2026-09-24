import SwiftUI

struct PebbleDisplayStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.largeTitle, design: .rounded).weight(.bold))
            .tracking(-0.5)
            .foregroundColor(.pebbleObsidian)
    }
}

struct PebbleTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.title, design: .rounded).weight(.bold))
            .tracking(-0.5)
            .foregroundColor(.pebbleObsidian)
    }
}

struct PebbleTitle2Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.title2, design: .rounded).weight(.semibold))
            .tracking(-0.3)
            .foregroundColor(.pebbleObsidian)
    }
}

struct PebbleTitle3Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .foregroundColor(.pebbleObsidian)
    }
}

struct PebbleHeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundColor(.pebbleObsidian)
    }
}

struct PebbleBodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.subheadline, design: .default))
            .foregroundColor(.pebbleSlate)
    }
}

struct PebbleCaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.caption, design: .rounded).weight(.medium))
            .foregroundColor(.pebbleStone)
            .textCase(.uppercase)
    }
}

struct PebbleMetricStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.title, design: .rounded).weight(.bold))
            .foregroundColor(.pebbleObsidian)
    }
}

struct PebbleLargeMetricStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .tracking(-1)
            .foregroundColor(.pebbleObsidian)
    }
}

extension View {
    func pebbleDisplay() -> some View { modifier(PebbleDisplayStyle()) }
    func pebbleTitle() -> some View { modifier(PebbleTitleStyle()) }
    func pebbleTitle2() -> some View { modifier(PebbleTitle2Style()) }
    func pebbleTitle3() -> some View { modifier(PebbleTitle3Style()) }
    func pebbleHeadline() -> some View { modifier(PebbleHeadlineStyle()) }
    func pebbleBody() -> some View { modifier(PebbleBodyStyle()) }
    func pebbleCaption() -> some View { modifier(PebbleCaptionStyle()) }
    func pebbleMetric() -> some View { modifier(PebbleMetricStyle()) }
    func pebbleLargeMetric() -> some View { modifier(PebbleLargeMetricStyle()) }
}
