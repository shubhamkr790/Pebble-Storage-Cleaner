import SwiftUI

struct StorageRingView: View {
    let storageInfo: StorageInfo
    @State private var animatedProgress: Double = 0

    private var usedFraction: Double {
        storageInfo.usedPercentage / 100.0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.pebbleCanvas, lineWidth: 18)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .pebbleSage,
                            .pebbleMint,
                            .pebbleSage.opacity(0.7),
                            .pebbleSage
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(Int(storageInfo.usedPercentage))%")
                    .pebbleLargeMetric()

                Text("used")
                    .pebbleCaption()

                Text("\(storageInfo.formattedUsed) / \(storageInfo.formattedTotal)")
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundColor(.pebbleStone)
            }
        }
        .frame(width: 200, height: 200)
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.3)) {
                animatedProgress = usedFraction
            }
        }
        .onChange(of: storageInfo.usedPercentage) { _, _ in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animatedProgress = usedFraction
            }
        }
    }
}
