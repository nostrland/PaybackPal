import SwiftUI
import Foundation

/// A stylized app icon rendering that depicts a Sai with a subtle red glow.
/// Designed to feel at home with Apple's iconography: simple geometry,
/// restrained gradients, and tasteful depth.
struct AppIconView: View {
    var size: CGFloat = 256
    var flatStyle: Bool = false

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: cornerRadius(for: size), style: .continuous)
                .fill(backgroundGradient)
                .overlay(vignette)
                .overlay(highlightStroke)

            // Red glow behind the symbol
            Circle()
                .fill(
                    RadialGradient(
                        colors: flatStyle ? [Color.red.opacity(0.25), Color.red.opacity(0.1), .clear]
                                          : [Color.red.opacity(0.55), Color.red.opacity(0.2), .clear],
                        center: .center,
                        startRadius: size * 0.05,
                        endRadius: size * 0.55
                    )
                )
                .blur(flatStyle ? size * 0.03 : size * 0.06)
                .scaleEffect(flatStyle ? 0.95 : 0.9)

            // Sai symbol
            SaiSymbol()
                .frame(width: size * 0.55, height: size * 0.65)
                .foregroundStyle(metalGradient)
                .shadow(color: .black.opacity(flatStyle ? 0.25 : 0.35), radius: size * 0.03, x: 0, y: size * 0.02)
                .shadow(color: .red.opacity(flatStyle ? 0.15 : 0.25), radius: size * 0.05, x: 0, y: 0)
                .overlay(
                    Group {
                        if !flatStyle {
                            SaiSymbol()
                                .frame(width: size * 0.55, height: size * 0.65)
                                .foregroundStyle(rimLightGradient)
                                .blendMode(.screen)
                                .opacity(0.5)
                        }
                    }
                )
        }
        .frame(width: size, height: size)
        .compositingGroup()
    }

    private var backgroundGradient: some ShapeStyle {
        LinearGradient(
            colors: [Color(red: 0.10, green: 0.10, blue: 0.11), Color(red: 0.02, green: 0.02, blue: 0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var vignette: some View {
        RoundedRectangle(cornerRadius: cornerRadius(for: size), style: .continuous)
            .fill(
                RadialGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.25)],
                    center: .center,
                    startRadius: size * 0.3,
                    endRadius: size * 0.8
                )
            )
            .blendMode(.multiply)
    }

    private var highlightStroke: some View {
        RoundedRectangle(cornerRadius: cornerRadius(for: size), style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: flatStyle ? [Color.white.opacity(0.15), Color.white.opacity(0.03)]
                                      : [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: max(1, size * 0.01)
            )
            .blendMode(.overlay)
    }

    private var metalGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(white: 0.92),
                Color(white: 0.80),
                Color(white: 0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var rimLightGradient: some ShapeStyle {
        AngularGradient(
            gradient: Gradient(colors: [
                .clear,
                .red.opacity(0.25),
                .clear,
                .white.opacity(0.3),
                .clear
            ]),
            center: .center
        )
    }

    private func cornerRadius(for size: CGFloat) -> CGFloat {
        // Rounded, but not too bubbly — similar to many system icons
        max(20, size * 0.18)
    }
}

// MARK: - Sai Symbol

/// A simplified, balanced Sai built from basic shapes so it scales cleanly.
private struct SaiSymbol: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let bladeWidth = w * 0.16
            let bladeHeight = h * 0.62
            let guardWidth = w * 0.72
            let guardHeight = h * 0.08
            let handleWidth = w * 0.14
            let handleHeight = h * 0.28
            let prongWidth = w * 0.14
            let prongHeight = h * 0.36

            ZStack {
                // Blade (top)
                RoundedRectangle(cornerRadius: bladeWidth * 0.35, style: .continuous)
                    .frame(width: bladeWidth, height: bladeHeight)
                    .offset(y: -h * 0.08)

                // Guard bar
                RoundedRectangle(cornerRadius: guardHeight * 0.5, style: .continuous)
                    .frame(width: guardWidth, height: guardHeight)
                    .offset(y: h * 0.08)

                // Side prongs
                RoundedRectangle(cornerRadius: prongWidth * 0.5, style: .continuous)
                    .frame(width: prongWidth, height: prongHeight)
                    .rotationEffect(.degrees(-35))
                    .offset(x: -w * 0.28, y: h * 0.02)

                RoundedRectangle(cornerRadius: prongWidth * 0.5, style: .continuous)
                    .frame(width: prongWidth, height: prongHeight)
                    .rotationEffect(.degrees(35))
                    .offset(x: w * 0.28, y: h * 0.02)

                // Handle
                RoundedRectangle(cornerRadius: handleWidth * 0.5, style: .continuous)
                    .frame(width: handleWidth, height: handleHeight)
                    .offset(y: h * 0.36)

                // Pommel
                Circle()
                    .frame(width: handleWidth * 0.85, height: handleWidth * 0.85)
                    .offset(y: h * 0.56)
            }
        }
    }
}

struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AppIconView(size: 256)
                .padding()
                .background(Color.black)
                .previewDisplayName("Icon 256")
            AppIconView(size: 1024)
                .padding()
                .background(Color.black)
                .previewDisplayName("Icon 1024")
            AppIconView(size: 128)
                .padding()
                .background(Color.black)
                .previewDisplayName("Icon 128")
            AppIconView(size: 64)
                .padding()
                .background(Color.black)
                .previewDisplayName("Icon 64")
            AppIconView(size: 256, flatStyle: true)
                .padding()
                .background(Color.black)
                .previewDisplayName("Icon 256 (Flat)")
        }
    }
}
