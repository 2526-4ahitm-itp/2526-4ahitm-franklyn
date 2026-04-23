import SwiftUI

private struct OnboardingSlide: Identifiable {
    let id: Int
    let tint: Color
    let softTint: Color
    let title: String
    let description: String
    let symbol: String
}

struct LoginLandingView: View {
    @EnvironmentObject private var loginService: LoginService
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSlide = 0

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            id: 0,
            tint: Color.blue,
            softTint: Color.cyan,
            title: "Monitor Exams Live",
            description: "Follow active exam sessions and monitor student devices with one clean, focused dashboard.",
            symbol: "person.crop.circle"
        ),
        OnboardingSlide(
            id: 1,
            tint: Color.indigo,
            softTint: Color.teal,
            title: "Track Activity Quickly",
            description: "See events as they happen and react quickly when something needs attention.",
            symbol: "waveform.path.ecg"
        ),
        OnboardingSlide(
            id: 2,
            tint: Color.green,
            softTint: Color.mint,
            title: "Secure Teacher Access",
            description: "Use your school account to keep exam data private and sessions protected.",
            symbol: "lock.shield"
        )
    ]

    private var currentSlide: OnboardingSlide {
        slides[selectedSlide]
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.09, blue: 0.11)
            : Color(red: 0.94, green: 0.95, blue: 0.97)
    }

    private var cardColor: Color {
        colorScheme == .dark
            ? Color(red: 0.14, green: 0.15, blue: 0.18)
            : .white
    }

    private var artworkBaseColor: Color {
        colorScheme == .dark
            ? Color(red: 0.18, green: 0.19, blue: 0.22)
            : Color(red: 0.98, green: 0.98, blue: 0.99)
    }

    private var controlBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.21, green: 0.22, blue: 0.26)
            : Color(red: 0.95, green: 0.96, blue: 0.98)
    }

    var body: some View {
        GeometryReader { proxy in
            let topInset = max(12, proxy.safeAreaInsets.top + 6)
            let bottomInset = max(12, proxy.safeAreaInsets.bottom + 6)

            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    Text("Franklyn")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    TabView(selection: $selectedSlide) {
                        ForEach(slides) { slide in
                            slideCard(slide)
                                .padding(.horizontal, 22)
                                .tag(slide.id)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    cardControls
                        .padding(.horizontal, 30)

                    Button {
                        loginService.discoverConfiguration(trigger: "landing-login")
                    } label: {
                        Text("Login")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.accentColor)
                            )
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, bottomInset)
                }
                .padding(.top, topInset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private func slideCard(_ slide: OnboardingSlide) -> some View {
        GeometryReader { geometry in
            let artworkHeight = max(180, geometry.size.height * 0.5)

            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(cardColor)
                    .shadow(color: .black.opacity(0.08), radius: 22, x: 0, y: 14)

                VStack(alignment: .leading, spacing: 0) {
                    artwork(slide)
                        .frame(height: artworkHeight)

                    VStack(alignment: .leading, spacing: 14) {
                        Text(slide.title)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(slide.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(4)
                            .lineSpacing(2)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func artwork(_ slide: OnboardingSlide) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(artworkBaseColor)

            Ellipse()
                .fill(slide.softTint.opacity(0.22))
                .frame(width: 220, height: 160)
                .offset(x: -110, y: 40)

            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(slide.tint.opacity(0.22))
                .frame(width: 260, height: 200)
                .offset(x: 120, y: 52)

            WaveLines(color: slide.tint.opacity(0.35))
                .frame(height: 120)
                .offset(y: -16)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [slide.softTint, slide.tint],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 172, height: 172)
                .overlay {
                    Image(systemName: slide.symbol)
                        .font(.system(size: 68, weight: .medium))
                        .foregroundStyle(.white)
                }
                .offset(y: 38)
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
    }

    private var cardControls: some View {
        HStack {
            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Circle()
                        .fill(index == selectedSlide ? currentSlide.tint : currentSlide.tint.opacity(0.3))
                        .frame(width: index == selectedSlide ? 8 : 6, height: index == selectedSlide ? 8 : 6)
                        .animation(.easeInOut(duration: 0.2), value: selectedSlide)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WaveLines: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let rows: [CGFloat] = [0.28, 0.44, 0.60]
            for row in rows {
                var path = Path()
                let startY = size.height * row
                path.move(to: CGPoint(x: 0, y: startY))
                path.addCurve(
                    to: CGPoint(x: size.width, y: startY + 2),
                    control1: CGPoint(x: size.width * 0.25, y: startY - 36),
                    control2: CGPoint(x: size.width * 0.70, y: startY + 34)
                )
                context.stroke(path, with: .color(color), lineWidth: 2)
            }
        }
    }
}

#Preview {
    LoginLandingView()
        .environmentObject(LoginService.shared)
}
