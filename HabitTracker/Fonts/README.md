# Custom Font: Dancing Script

Headings in the app use **Dancing Script**, a casual cursive script font from Google Fonts (OFL license, free for commercial use). It reads like friendly handwritten text.

## Add the font to the project

1. **Download** the font file:
   - **Direct:** [DancingScript-Regular.ttf](https://github.com/google/fonts/raw/main/ofl/dancingscript/DancingScript-Regular.ttf)
   - Or from [Google Fonts – Dancing Script](https://fonts.google.com/specimen/Dancing+Script) → Download family → use `DancingScript-Regular.ttf`

2. **Add to Xcode:**
   - Drag `DancingScript-Regular.ttf` into this `Fonts` folder in the Project Navigator (under HabitTracker).
   - In the dialog: check **Copy items if needed**, check the **HabitTracker** target.
   - Click **Finish**.

3. **Confirm registration:** `HabitTracker/Info.plist` already has `UIAppFonts` with `DancingScript-Regular.ttf`. If you added the file with another name, add that filename to the `UIAppFonts` array in Info.plist.

After adding the file, build and run; page titles (Home, Calendar, Statistics, Settings) will use Dancing Script. If the font is missing, the app falls back to the system font.

## Other cursive options (same steps, different file)

If you prefer a different style, you can swap the font:

| Font           | Style              | File name              | Google Fonts link |
|----------------|--------------------|------------------------|-------------------|
| **Dancing Script** (current) | Casual, readable script | `DancingScript-Regular.ttf` | [Dancing Script](https://fonts.google.com/specimen/Dancing+Script) |
| **Great Vibes**     | Elegant, flowing   | `GreatVibes-Regular.ttf`   | [Great Vibes](https://fonts.google.com/specimen/Great+Vibes) |
| **Sacramento**      | Thin, elegant      | `Sacramento-Regular.ttf`   | [Sacramento](https://fonts.google.com/specimen/Sacramento) |
| **Caveat**          | Natural handwriting| `Caveat-Regular.ttf`       | [Caveat](https://fonts.google.com/specimen/Caveat) |
| **Allura**          | Formal script      | `Allura-Regular.ttf`       | [Allura](https://fonts.google.com/specimen/Allura) |

Use the font’s **family name** (e.g. `"Dancing Script"`, `"Great Vibes"`) in `AppTheme.swift` as `cursiveFontName`, and add the `.ttf` file plus its name in Info.plist `UIAppFonts`.
