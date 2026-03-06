# Putting Ads in the Home Page Ad Card

The home page already has an **Ad Card** slot that shows either a placeholder or a real ad. You can fill it in two ways.

---

## Option 1: Apple AdAttributionKit (current wiring)

The app is already set up for **App Impressions** (AdAttributionKit, iOS 17.4+). When an ad network gives you a **compact JWS** string for an impression, the card shows that ad and records view/click attribution.

### Step 1: Find an ad network that supports App Impressions

- Use a network that supports [App Impressions / AdAttributionKit](https://developer.apple.com/documentation/adattributionkit).
- Sign up as a publisher and get:
  - Your **ad network identifier** (e.g. `example.adattributionkit`).
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

Whenever the network gives you a new ad impression (a compact JWS string), assign it in your app. The ad card reads from `AdService.currentImpressionJWS`.

**On the main thread** (e.g. in a completion handler or async MainActor code):

```swift
AdService.currentImpressionJWS = "eyJ..."  // The compact JWS from the network
```

- If you use the network’s **SDK**: in their callback that delivers the JWS, set `AdService.currentImpressionJWS = jwsString`.
- If you use a **backend**: when your app receives the JWS (e.g. from an API response), set `AdService.currentImpressionJWS` with that value.

The existing **AdBannerContentView** on the home page will then show the ad and handle view/click attribution automatically.

### Step 4: Refresh ads when you get a new impression

- When the network sends a **new** JWS (e.g. for a new impression or after a timeout), set it again:  
  `AdService.currentImpressionJWS = newJWSString`
- You can refresh based on:
  - A timer (e.g. every 60 seconds),
  - When the home screen appears (`onAppear`),
  - Or whenever the network’s SDK/API provides a new JWS.

---

## Option 2: Google AdMob (or another SDK banner)

If you prefer **Google AdMob** (or a similar SDK), you show a banner view inside the same card and do **not** use the JWS path.

### Steps

1. **Add the SDK**
   - Add [Google Mobile Ads](https://developers.google.com/admob/ios/quick-start) via Swift Package Manager (or CocoaPods).
   - In the App’s initialization, call `GADMobileAds.sharedInstance().start(completionHandler: nil)`.

2. **Create an ad unit**
   - In [AdMob](https://admob.google.com) create an app and a **Banner** ad unit; copy the **Ad unit ID**.

3. **Info.plist**
   - Add your AdMob App ID, e.g.:
   - Key: `GADApplicationIdentifier`
   - Value: `ca-app-pub-xxxxxxxx~yyyyyyyyyy` (your app ID from AdMob).

4. **Replace or wrap the banner content**
   - The card is built in `HabitTracker/Views/Home/HomeComponents.swift` (`AdCardView`) and `AdBannerView.swift` (`AdBannerContentView`).
   - Add a **UIViewRepresentable** that creates a `GADBannerView`, sets the ad unit ID, and loads a request (e.g. `GADRequest()`).
   - In `AdCardView`, instead of (or in addition to) `AdBannerContentView(jws: AdService.currentImpressionJWS)`, present this AdMob banner view so it sits inside the same “Advertisement” card.

5. **Optional: App Tracking Transparency**
   - If you use personalized ads, add the **App Tracking Transparency** capability and request `ATTrackingManager.requestTrackingAuthorization` when appropriate; pass the result into ad request if needed.

---

## Summary

| Approach              | Best if you…                          | Where to plug in                          |
|-----------------------|----------------------------------------|------------------------------------------|
| **AdAttributionKit**  | Have a partner that gives you JWS      | Set `AdService.currentImpressionJWS` + Info.plist `AdNetworkIdentifiers` |
| **AdMob (or similar)**| Want a standard banner from Google etc.| Add SDK, then a `GADBannerView` inside `AdCardView` / `AdBannerContentView` |

The **physical slot** is always the same: the “Advertisement” card on the home screen. You only choose whether to fill it via AdAttributionKit (JWS) or via an SDK banner view.
