import Foundation

/// Provides the current ad impression for the home ad slot (Apple AdAttributionKit).
/// When you partner with an AdAttributionKit-registered ad network:
/// 1. Add the network’s ID to Info.plist under `AdNetworkIdentifiers` (e.g. `"abc123.adattributionkit"`).
/// 2. Set `currentImpressionJWS` with the compact JWS string they provide; the app will display the ad and record view/click attribution.
enum AdService {
    /// Compact JWS string for the current ad impression. Set by your ad network SDK or API when you integrate one.
    /// Leave nil to show the placeholder until you have an ad network.
    static var currentImpressionJWS: String?
}
