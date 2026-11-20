# App Store marketing images

`render.py` turns raw simulator screenshots into App Store images:

- `iphone-01..08-*.png` (1320 x 2868, iPhone 6.9" screenshots)
- `creative-header-3840x1646.png` (product page header, 21:9)
- `creative-search-3840x2560.png` (search results creative, 3:2)

## 1. Capture fresh screens

Devices and folders:

| folder | device | size |
|---|---|---|
| raw/iphone/ | iPhone 18 Pro Max simulator | 1320 x 2868 |
| raw/ipad/ | iPad Pro 13-inch simulator | 2064 x 2752 |
| raw/mac/ | Mac app window, full-screen capture | 2880 x 1800 |


Run the latest build, add the demo habits (Drink Water, Exercise, Journal, Plan Tomorrow,
Practice Instrument, Read a book), complete a few, then for each screen:

```sh
xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3
xcrun simctl io booted screenshot marketing/raw/home_light.png
```

File names the script expects (same names in `raw/iphone/` and `raw/ipad/`; Mac uses `home`, `calendar`, `stats`, `detail`, `templates` with `_light`/`_dark`):

| file | screen |
|---|---|
| home_light.png | Home, light mode, a few habits left |
| home_dark_progress.png | Home, dark mode, scrolled to top, 3 of 6 done |
| streaks_dark.png | Stats > Current Streaks sheet, dark |
| week_dark.png | Calendar > Weekly, dark |
| stats_light.png | Stats, light |
| widget.png | Home Screen with the Habit widget |
| templates_dark.png | Templates sheet, dark |
| detail_light.png | A habit's detail sheet, light |
| icon.png | `HabitTracker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` |

Make sure no ad banner is visible (buy Remove Ads in the sandbox or use a debug build without ads):
App Review rejects screenshots that show third-party ads.

## 2. Render

```sh
pip install playwright pillow && playwright install chromium
python3 marketing/render.py marketing/raw marketing/appstore
```
