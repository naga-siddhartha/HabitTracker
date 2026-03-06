# Putting Ads in the Home Page Ad Card

The home page has an **Ad Card** slot on **iOS** that shows a banner ad. You can fill it in two ways.

---

## Option 1: Apple AdAttributionKit (not implemented)

To use **App Impressions** (AdAttributionKit, iOS 17.4+), you would add code that receives a **compact JWS** string from an ad network and a view that displays it and records view/click attribution. The following steps describe what to implement.

### Step 1: Find an ad network that supports App Impressions

Apple does not publish a single “supported networks” list. Use the following to find a partner:

- **Apple’s docs**
  - [AdAttributionKit](https://developer.apple.com/documentation/adattributionkit) – overview.
  - [Configuring a publisher app](https://developer.apple.com/documentation/AdAttributionKit/configuring-a-publisher-app) – what you need (e.g. `AdNetworkIdentifiers`).
  - [Registering an ad network](https://developer.apple.com/documentation/AdAttributionKit/registering-an-ad-network) – how networks get an ID; any such network *can* support App Impressions.
- **Registered networks**
  - Ad networks register with Apple and get an ad network ID (e.g. `example123.skadnetwork`). AdAttributionKit is interoperable with SKAdNetwork.
  - **IAB Tech Lab [SKAdNetwork ID list](https://iabtechlab.com/software/skadnetwork-id-list/)** – many ad networks register here; you can see who has IDs. Then contact them and ask: “Do you support **App Impressions** (AdAttributionKit) for **publishers** and can you deliver **compact JWS** for in-app display?”
- **What to ask any network**
  - “Do you support Apple’s App Impressions / AdAttributionKit for publisher apps?”
  - “Can you supply **compact JWS** strings for each impression so we can display the ad and record view/click attribution?”
  - “What is your **ad network identifier** (for our Info.plist `AdNetworkIdentifiers`)?”
- **Where to look**
  - Mediation / demand platforms you already use (e.g. **Google AdMob**, **AppLovin MAX**, **Unity Ads**) – ask if they support App Impressions and JWS for publishers.
  - Networks that run app-install campaigns (Meta, Google, TikTok, etc.) – some may offer publisher inventory with AdAttributionKit; confirm with their publisher or partner docs/support.

Once you have a partner, sign up as a publisher and get:

- Their **ad network identifier** (e.g. `example123.skadnetwork`).
- A way to receive **compact JWS** strings for each ad impression (e.g. from their SDK, API, or server callback).

### Step 2: Add the network identifier in Info.plist

1. Open **HabitTracker/Info.plist** in Xcode (or a text editor).
2. Find the key **`AdNetworkIdentifiers`** (it’s an array, currently empty).
3. Add a new array item with the network’s identifier string.

Example (Xcode: click the `+` under `AdNetworkIdentifiers` and enter the string):

```xml
<key>AdNetworkIdentifiers</key>
<array>
    <string>your-network-id.adattributionkit</string>
</array>
```

Replace `your-network-id.adattributionkit` with the value your network gave you.

### Step 3: Set the JWS when you receive an impression

Add a shared place (e.g. a singleton or `@Observable` state) to hold the current JWS. Whenever the network gives you a new ad impression, set it on the main thread. Your custom view would read from this and display the ad via AdAttributionKit (e.g. `AppImpression(compactJWS:)`, `EventAttributionOverlayView`, `beginView`/`endView`/`handleTap`).

### Step 4: Refresh ads when you get a new impression

When the network sends a new JWS, update your stored value. Refresh based on a timer, `onAppear`, or the network’s SDK/API.

---

## Option 2: Google AdMob (or another SDK banner) — **implemented**

Google AdMob banner ads are integrated on the **iOS** home page. The same “Advertisement” card shows a live banner from the Google Mobile Ads SDK.

**iOS vs macOS:** The Google Mobile Ads SDK only provides iOS libraries (no macOS or visionOS). The project has two app targets: **HabitTracker** (iOS only, with AdMob) and **HabitTracker Mac** (macOS only, no AdMob). Use the **HabitTracker** scheme to build/run on iPhone; use the **HabitTracker Mac** scheme to build/run on Mac. The ad card is only shown on iOS; it is not shown on macOS.

### What’s in place

1. **SDK**
   - [Google Mobile Ads](https://developers.google.com/admob/ios/quick-start) is added via Swift Package Manager (`https://github.com/googleads/swift-package-manager-google-mobile-ads`).
   - The app calls `MobileAds.shared.start(completionHandler:)` after launch (iOS only), with test device IDs set so test ads can be requested.

2. **Info.plist**
   - `GADApplicationIdentifier`: your AdMob app ID (use the test ID while developing).
   - `SKAdNetworkItems`: set of SKAdNetwork identifiers required by the SDK.

3. **Banner implementation**
   - `HabitTracker/Views/Home/AdMobBannerView.swift`: SwiftUI view that wraps a `BannerView` in a `UIViewRepresentable`, using **large anchored adaptive** banner size and your banner ad unit ID.
   - `AdCardView` in `HomeComponents.swift`: on **iOS** it shows `AdMobBannerView()`; the ad card is not shown on macOS.

### Before release (production)

1. **Create an AdMob app and banner ad unit**
   - In [AdMob](https://admob.google.com) create an app and a **Banner** ad unit; copy the **App ID** and **Ad unit ID**.

2. **Switch from test IDs to production**
   - In **Info.plist**: replace `GADApplicationIdentifier` with your real AdMob app ID (e.g. `ca-app-pub-xxxxxxxx~yyyyyyyyyy`).
   - In **AdMobBannerView.swift**: replace `bannerAdUnitID` with your production banner ad unit ID (and remove or guard the test ID comment).

3. **Optional: App Tracking Transparency**
   - If you use personalized ads, add the **App Tracking Transparency** capability and request `ATTrackingManager.requestTrackingAuthorization` when appropriate; pass the result into the ad request if needed.

4. **Optional: more SKAdNetwork IDs**
   - You can add more entries to `SKAdNetworkItems` in Info.plist from [Google’s full list](https://developers.google.com/admob/ios/quick-start#update_your_infoplist).

---

## Summary

| Approach              | Best if you…                          | Where to plug in                          |
|-----------------------|----------------------------------------|------------------------------------------|
| **AdAttributionKit**  | Have a partner that gives you JWS      | Implement a store for JWS + a view using AdAttributionKit; add Info.plist `AdNetworkIdentifiers` |
| **AdMob (implemented)**| Want a standard banner from Google     | `AdMobBannerView` inside `AdCardView` on iOS |

The ad card is shown only on **iOS**; it uses AdMob. To use AdAttributionKit instead, you would add the integration described in Option 1.
