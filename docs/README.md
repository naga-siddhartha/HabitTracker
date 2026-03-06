# GitHub Pages for Habits

This folder contains the **Privacy Policy** page for the Habits app, for use with GitHub Pages.

## Setup

1. In your HabitTracker repo on GitHub: **Settings → Pages**.
2. Under **Source**, choose **Deploy from a branch**.
3. Branch: **main** (or **master**), folder: **/docs**.
4. Save. GitHub will serve the contents of `docs/` at:
   ```
   https://<your-username>.github.io/HabitTracker/
   ```

## Privacy policy URL

After Pages is published, your privacy policy will be at:

```
https://<your-username>.github.io/HabitTracker/privacy.html
```

Many servers allow dropping the `.html` extension, so this may also work:

```
https://<your-username>.github.io/HabitTracker/privacy
```

Use one of these as **PrivacyPolicyURL** in `HabitTracker/Info.plist` and in App Store Connect.

## Files

- **privacy.html** — Privacy policy page (required for App Store).
