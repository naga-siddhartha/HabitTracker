import SwiftUI
#if os(iOS)
import AdAttributionKit
import UIKit
#endif

private let adContentHeight: CGFloat = 50

// MARK: - Ad banner content (placeholder or AdAttributionKit-backed)

struct AdBannerContentView: View {
    let jws: String?
    @Environment(\.colorScheme) private var colorScheme
    #if os(iOS)
    @State private var impression: AppImpression?
    private var canShowAttributionAd: Bool {
        guard impression != nil else { return false }
        if #available(iOS 18.0, *) { return AppImpression.isSupported }
        return true
    }
    #endif

    var body: some View {
        Group {
            #if os(iOS)
            if #available(iOS 17.4, *), let impression, canShowAttributionAd {
                AdAttributionBannerView(impression: impression, colorScheme: colorScheme)
            } else {
                adPlaceholder
            }
            #else
            adPlaceholder
            #endif
        }
        #if os(iOS)
        .task(id: jws) {
            guard #available(iOS 17.4, *), let jws else { impression = nil; return }
            impression = try? await AppImpression(compactJWS: jws)
        }
        #endif
    }

    private var adPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.05))
            .frame(height: adContentHeight)
            .overlay {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 20))
                    .foregroundStyle(.tertiary)
            }
    }
}

#if os(iOS)
@available(iOS 17.4, *)
private struct AdAttributionBannerView: View {
    let impression: AppImpression
    let colorScheme: ColorScheme
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.05))
                .frame(height: adContentHeight)
                .overlay {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 20))
                        .foregroundStyle(.tertiary)
                }
            EventAttributionOverlayView()
        }
        .frame(height: adContentHeight)
        .contentShape(Rectangle())
        .onTapGesture { handleTap() }
        .onAppear { beginViewIfNeeded() }
        .onDisappear { endViewIfNeeded() }
    }

    private func beginViewIfNeeded() {
        guard !hasAppeared else { return }
        hasAppeared = true
        Task {
            do {
                try await impression.beginView()
            } catch {
                // View not visible long enough or already ended; ignore.
            }
        }
    }

    private func endViewIfNeeded() {
        guard hasAppeared else { return }
        hasAppeared = false
        Task {
            do {
                try await impression.endView()
            } catch {
                // Ignore (e.g. view was visible < 2 seconds).
            }
        }
    }

    private func handleTap() {
        Task {
            do {
                try await impression.handleTap()
            } catch {
                // Tap validation failed (e.g. not on UIEventAttributionView) or impression expired.
            }
        }
    }
}

@available(iOS 17.4, *)
private struct EventAttributionOverlayView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIEventAttributionView {
        let view = UIEventAttributionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    func updateUIView(_ uiView: UIEventAttributionView, context: Context) {}
}
#endif
