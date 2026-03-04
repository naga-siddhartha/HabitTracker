# Custom Font: Dancing Script

Headings in the app use **Dancing Script**, a casual cursive script font from Google Fonts (OFL license, free for commercial use).

## Add the font to the project

1. **Download** the font file:
   - [DancingScript-Regular.ttf](https://github.com/google/fonts/raw/main/ofl/dancingscript/DancingScript-Regular.ttf)
   - Or [Google Fonts – Dancing Script](https://fonts.google.com/specimen/Dancing+Script) → Download family → use `DancingScript-Regular.ttf`

2. **Add to Xcode:** Drag `DancingScript-Regular.ttf` into this `Fonts` folder. Check **Copy items if needed** and the **HabitTracker** target.

3. **Registration:** `Info.plist` already lists `DancingScript-Regular.ttf` under `UIAppFonts`. If you use a different filename, add it there.

After adding the file, build and run; page titles use Dancing Script. If the font is missing, the app falls back to the system font (see `AppTheme.swift`).
