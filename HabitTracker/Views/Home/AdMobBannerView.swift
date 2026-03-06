#if os(iOS)
import SwiftUI
import UIKit
import GoogleMobileAds

// MARK: - AdMob banner (Google Mobile Ads) for home page ad card

/// Test banner ad unit ID. Replace with your production ID before release.
/// See: https://developers.google.com/admob/ios/banner#always_test_with_test_ads
private let bannerAdUnitID = "ca-app-pub-1864456501435529/5973868320"

/// Anchored adaptive banner height (max 20% of screen, 150pt max). Use fixed height for stable layout.
private let bannerPlaceholderHeight: CGFloat = 50

struct AdMobBannerView: View {
    var body: some View {
        AdMobBannerRepresentable()
            .frame(maxWidth: .infinity)
            .frame(height: bannerPlaceholderHeight)
    }
}

// MARK: - UIViewRepresentable

private struct AdMobBannerRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let containerWidth = UIScreen.main.bounds.width - 32 // Card padding
        let width = max(containerWidth, 320)
        let adSize = largeAnchoredAdaptiveBanner(width: width)
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = bannerAdUnitID
        banner.delegate = context.coordinator
        banner.rootViewController = Self.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private static var rootViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        return windowScene.windows.first(where: \.isKeyWindow)?.rootViewController
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {}

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {}
    }
}
#endif
