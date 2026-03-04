# App Store submission checklist

This checklist is based on [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) and helps ensure Habits is ready for submission.

## Before you submit

### 1. Replace placeholder URLs (required)

The app reads **Privacy Policy** and **Support** URLs from `Info.plist`. Before submitting:

1. Open **HabitTracker/Info.plist** in Xcode.
2. Set **PrivacyPolicyURL** to your real privacy policy URL (e.g. `https://yoursite.com/privacy`).
3. Set **SupportURL** to your support/contact page or mailto (e.g. `https://yoursite.com/support` or `mailto:support@yourapp.com`).

Guidelines **1.5** (Developer Information) and **5.1.1** (Privacy) require an easy way to contact you and a privacy policy link **in the app** and in App Store Connect.

### 2. App Store Connect metadata

- **Privacy Policy URL**: Enter the same URL as in Info.plist (required by 5.1.1).
- **Support URL**: Enter the same support/contact URL (required by 1.5).
- **Contact information**: Keep your developer account contact info up to date so App Review can reach you.
- **App description, screenshots, previews**: Must accurately reflect the app (2.3). Screenshots should show the app in use, not only splash/login (2.3.3).
- **Category**: Choose the most appropriate category (e.g. Health & Fitness or Productivity) (2.3.5).
- **Age rating**: Answer the questionnaire honestly in App Store Connect (2.3.6).
- **Keywords & app name**: No trademarked terms or irrelevant phrases (2.3.7).

### 3. Privacy policy content

Your privacy policy must clearly state (5.1.1):

- What data the app collects (e.g. habit names, completion dates, reminder settings — all stored only on device).
- How data is collected and used (local storage via SwiftData; optional local notifications).
- That no user data is sent to servers (this app has no network calls).
- Data retention/deletion (e.g. user can reset all data in Settings; uninstall removes data).
- How users can revoke consent or request deletion (e.g. Reset All Data in Settings).

### 4. Testing

- Test on a real device for crashes and bugs (2.1).
- Ensure all features work: creating/editing habits, calendar, stats, export, widget, Siri Shortcuts.
- If you use a demo account or backend, ensure it’s live and accessible during review (not applicable here — app is fully local).

### 5. Optional: Export compliance

If your app uses encryption only in standard OS APIs (HTTPS, etc.), you can select “No” for export compliance in App Store Connect. This app does not use custom encryption.

---

## What’s already in place

- **Privacy & Support in app**: Settings → Support shows “Privacy Policy” and “Contact & Support” that open the URLs from Info.plist (5.1.1, 1.5).
- **No remote notifications**: Only local notifications are used; `UIBackgroundModes` does not declare `remote-notification` (avoids confusion with 2.5.4).
- **No in-app purchase**: No StoreKit or external purchase flows; no guideline 3.1 issues.
- **No login required**: App works without an account (5.1.1(v)).
- **Data is local**: SwiftData, no CloudKit/network; no third-party analytics or SDKs (privacy-friendly).
- **Widget**: Related to app content (habits) (2.5.16).
- **Siri/Shortcuts**: Toggle habit intent is focused and uses app name in phrases (2.5.11).
- **No hidden features**: Functionality is clear to users and review (2.3.1).

Replace the placeholder URLs, publish your privacy policy, and fill in App Store Connect as above before submitting.
