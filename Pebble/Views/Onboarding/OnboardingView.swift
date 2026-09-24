import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.pebbleCanvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $viewModel.currentPage) {
                    ForEach(Array(viewModel.slides.enumerated()), id: \.element.id) { index, slide in
                        slideView(slide: slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.currentPage)

                bottomSection
            }
        }
        .onChange(of: viewModel.isCompleted) { _, completed in
            if completed { onComplete() }
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                ForEach(0..<viewModel.slides.count, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == viewModel.currentPage ? Color.pebbleSage : Color.pebbleStone.opacity(0.25))
                        .frame(
                            width: index == viewModel.currentPage ? 24 : 8,
                            height: 8
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentPage)
                }
            }

            Spacer()

            if !viewModel.isLastSlide {
                Button {
                    viewModel.skip()
                } label: {
                    Text("Skip")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(.pebbleStone)
                }
            }
        }
        .padding(.horizontal, PebbleLayout.screenPadding)
        .padding(.top, 16)
    }

    private func slideView(slide: OnboardingSlide) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: slide.gradientColors + [Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)

                floatingShapes(for: slide)

                Image(systemName: slide.iconName)
                    .font(.system(size: 72, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pebbleSage, .pebbleMint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(height: 300)

            VStack(spacing: 16) {
                Text(slide.title)
                    .pebbleTitle()
                    .multilineTextAlignment(.center)

                Text(slide.subtitle)
                    .pebbleBody()
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    @ViewBuilder
    private func floatingShapes(for slide: OnboardingSlide) -> some View {
        Group {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.pebbleMint.opacity(0.15))
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(15))
                .offset(x: -100, y: -60)

            Circle()
                .fill(Color.pebbleCoral.opacity(0.12))
                .frame(width: 24, height: 24)
                .offset(x: 90, y: -80)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.pebbleViolet.opacity(0.12))
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(-20))
                .offset(x: 110, y: 50)

            Circle()
                .fill(Color.pebbleOchre.opacity(0.12))
                .frame(width: 18, height: 18)
                .offset(x: -80, y: 90)
        }
    }

    private var bottomSection: some View {
        VStack(spacing: 16) {
            if viewModel.isLastSlide {
                PebblePillButton("Get Started", icon: "arrow.right") {
                    viewModel.complete()
                }
            } else {
                PebblePillButton("Continue", icon: "arrow.right") {
                    viewModel.nextPage()
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.pebbleSage.opacity(0.6))

                Text("All scanning runs locally on your iPhone.")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.pebbleStone)
            }
        }
        .padding(.horizontal, PebbleLayout.screenPadding)
        .padding(.bottom, 40)
    }
}
