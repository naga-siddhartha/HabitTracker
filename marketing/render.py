"""Render App Store marketing images for Habit: Grab It.

Usage: python3 render.py <raw_dir> <out_dir>
<raw_dir> holds iphone/ and ipad/ folders of simulator captures plus icon.png.
Outputs: iphone-*.png 1320x2868, ipad-*.png 2064x2752,
creative-header-3840x1646.png, creative-search-3840x2560.png.

Design: flat brand colors, one typeface (Inter, close to SF Pro), left-aligned,
sentence-case headlines, real device proportions. No gradients, no glow.
"""
import base64, sys, pathlib, shutil
from playwright.sync_api import sync_playwright
from PIL import Image

RAW = pathlib.Path(sys.argv[1]); OUT = pathlib.Path(sys.argv[2]); OUT.mkdir(parents=True, exist_ok=True)

def data(path):
    return "data:image/png;base64," + base64.b64encode(pathlib.Path(path).read_bytes()).decode()

# Brand: violet #A04AC8 (app accent). Backgrounds are calm, flat versions of it.
THEMES = {
    "brand": dict(bg="#7B34A6", fg="#FFFFFF", sub="rgba(255,255,255,.72)"),
    "light": dict(bg="#F5F2F8", fg="#17101F", sub="#6E6478"),
    "dark":  dict(bg="#120D18", fg="#F5F0FA", sub="#9C92A8"),
}

SLIDES = [
    # name, screen, headline, subline, theme
    ("01-hero", "home_light.png", "Build habits<br>that stick.", "Simple, private, no account needed.", "brand"),
    ("02-tap", "home_dark_progress.png", "One tap<br>and it's done.", "Your day, sorted by what's next.", "dark"),
    ("03-streaks", "streaks_dark.png", "Every streak<br>in one place.", "Current and best, side by side.", "dark"),
    ("04-week", "week_dark.png", "Your week<br>at a glance.", "See which days you showed up.", "dark"),
    ("05-stats", "stats_light.png", "Know what's<br>working.", "A year of progress on one screen.", "light"),
    ("06-widget", "widget.png", "Right on your<br>Home Screen.", "Check in without opening the app.", "brand"),
    ("07-templates", "templates_dark.png", "Start with<br>a template.", "Health, focus, mindfulness and more.", "dark"),
    ("08-detail", "detail_light.png", "The details,<br>when you want them.", "Schedule and streaks for every habit.", "light"),
]

DEVICES = {
    # canvas, text margin, device width, screen corner radius, bezel, text sizes
    "iphone": dict(w=1320, h=2868, pad=110, dw=1040, sr=118, bz=22, top=210, h1=112, h2=46, gap=130, icon=132),
    "ipad":   dict(w=2064, h=2752, pad=160, dw=1700, sr=56, bz=30, top=200, h1=132, h2=54, gap=130, icon=150),
}

BASE_CSS = """
*{margin:0;padding:0;box-sizing:border-box}
body{overflow:hidden;font-family:'Inter Display','Inter',sans-serif;-webkit-font-smoothing:antialiased;position:relative}
h1{font-weight:600;letter-spacing:-0.035em;line-height:1.02}
p{font-family:'Inter',sans-serif;font-weight:400;letter-spacing:-0.01em}
.dev{position:absolute;left:50%;transform:translateX(-50%);background:#0A0A0C;
  box-shadow:0 0 0 2px rgba(255,255,255,.06) inset, 0 50px 120px rgba(10,0,20,.22)}
.dev img{display:block;width:100%;height:100%}
"""

def slide(dev, screen, h1, sub, theme, hero):
    D, T = DEVICES[dev], THEMES[theme]
    shot = Image.open(RAW / dev / screen)
    dh = int(D["dw"] * shot.height / shot.width)
    icon = f'<img src="{data(RAW / dev / "icon.png")}" style="position:absolute;left:{D["pad"]}px;top:{D["top"]}px;width:{D["icon"]}px;height:{D["icon"]}px;border-radius:22.5%">' if hero else ""
    ty = D["top"] + (D["icon"] + 56 if hero else 0)
    return f"""<html><head><style>{BASE_CSS}
body{{width:{D['w']}px;height:{D['h']}px;background:{T['bg']};color:{T['fg']}}}
h1{{position:absolute;left:{D['pad']}px;top:{ty}px;font-size:{D['h1']}px}}
p{{position:absolute;left:{D['pad']}px;top:{ty + int(D['h1']*2.04) + 34}px;font-size:{D['h2']}px;color:{T['sub']}}}
.dev{{top:{ty + int(D['h1']*2.04) + 34 + int(D['h2']*1.3) + D['gap']}px;width:{D['dw'] + 2*D['bz']}px;height:{dh + 2*D['bz']}px;padding:{D['bz']}px;border-radius:{D['sr'] + D['bz']}px}}
.dev img{{border-radius:{D['sr']}px}}
</style></head><body>{icon}<h1>{h1}</h1><p>{sub}</p>
<div class=dev><img src="{data(RAW / dev / screen)}"></div></body></html>"""

def wide(w, h, kind):
    T = THEMES["brand"]; ph = RAW / "iphone"
    if kind == "header":   # keep text inside the middle band; edges crop by orientation
        tx, ty, fs, ic, phones = 640, 520, 140, 150, [("home_light.png", 2240, 300, 700), ("home_dark_progress.png", 2840, 180, 700)]
    else:
        tx, ty, fs, ic, phones = 300, 760, 170, 180, [("home_light.png", 1960, 380, 820), ("home_dark_progress.png", 2780, 260, 820)]
    devs = ""
    for s, x, y, dw in phones:
        dh = int(dw * 2868 / 1320); bz = int(dw * .022); r = int(dw * .118)
        devs += f'<div class=dev style="left:{x}px;top:{y}px;transform:none;width:{dw+2*bz}px;height:{dh+2*bz}px;padding:{bz}px;border-radius:{r+bz}px"><img src="{data(ph / s)}" style="border-radius:{r}px"></div>'
    return f"""<html><head><style>{BASE_CSS}
body{{width:{w}px;height:{h}px;background:{T['bg']};color:{T['fg']}}}
h1{{position:absolute;left:{tx}px;top:{ty + ic + 70}px;font-size:{fs}px}}
p{{position:absolute;left:{tx}px;top:{ty + ic + 70 + int(fs*2.04) + 40}px;font-size:{int(fs*.36)}px;color:{T['sub']}}}
</style></head><body><img src="{data(ph / 'icon.png')}" style="position:absolute;left:{tx}px;top:{ty}px;width:{ic}px;border-radius:22.5%">
<h1>Build habits<br>that stick.</h1><p>Simple, private, no account needed.</p>{devs}</body></html>"""

with sync_playwright() as p:
    chrome = shutil.which("google-chrome")
    b = p.chromium.launch(executable_path=chrome) if chrome else p.chromium.launch()
    for dev, D in DEVICES.items():
        if not (RAW / dev).is_dir():
            continue
        pg = b.new_page(viewport={"width": D["w"], "height": D["h"]})
        for name, screen, h1, sub, theme in SLIDES:
            pg.set_content(slide(dev, screen, h1, sub, theme, name.endswith("hero"))); pg.wait_for_timeout(150)
            pg.screenshot(path=str(OUT / f"{dev}-{name}.png"))
    for kind, w, h in [("header", 3840, 1646), ("search", 3840, 2560)]:
        pg = b.new_page(viewport={"width": w, "height": h})
        pg.set_content(wide(w, h, kind)); pg.wait_for_timeout(200)
        pg.screenshot(path=str(OUT / f"creative-{kind}-{w}x{h}.png"))
    b.close()

# App Store rejects alpha channels.
for f in OUT.glob("*.png"):
    im = Image.open(f)
    if im.mode != "RGB":
        im.convert("RGB").save(f)
print("done", len(list(OUT.glob("*.png"))), "images")

# ---- Mac: 2880x1800, text column left, app window right (bleeds off the edge) ----
MAC_SLIDES = [
    ("01-hero", "home_light.png", "Build habits<br>that stick.", "Now on Mac, synced with your iPhone.", "brand"),
    ("02-click", "home_dark.png", "One click<br>and it's done.", "Your day, sorted by what's next.", "dark"),
    ("03-month", "calendar_light.png", "Your month<br>at a glance.", "See which days you showed up.", "light"),
    ("04-week", "calendar_dark.png", "Every habit,<br>every day.", "A week of progress in one view.", "dark"),
    ("05-stats", "stats_dark.png", "Know what's<br>working.", "A year of progress on one screen.", "dark"),
    ("06-detail", "detail_light.png", "Every detail,<br>one click away.", "Schedule and streaks for every habit.", "light"),
    ("07-templates", "templates_light.png", "Start with<br>a template.", "Health, focus, mindfulness and more.", "light"),
]

def mac_slide(screen, h1, sub, theme, hero):
    T = THEMES[theme]; src = RAW / "mac"
    icon = f'<img src="{data(RAW / "iphone" / "icon.png")}" style="position:absolute;left:150px;top:420px;width:150px;border-radius:22.5%">' if hero else ""
    ty = 640 if hero else 600
    return f"""<html><head><style>{BASE_CSS}
body{{width:2880px;height:1800px;background:{T['bg']};color:{T['fg']}}}
h1{{position:absolute;left:150px;top:{ty}px;font-size:128px}}
p{{position:absolute;left:150px;top:{ty + 300}px;font-size:52px;color:{T['sub']};width:760px;line-height:1.3}}
.win{{position:absolute;left:1080px;top:250px;width:2240px;border-radius:26px;overflow:hidden;
  box-shadow:0 0 0 1.5px rgba(0,0,0,.12), 0 40px 110px rgba(10,0,20,.28)}}
.win img{{display:block;width:100%}}
</style></head><body>{icon}<h1>{h1}</h1><p>{sub}</p>
<div class=win><img src="{data(src / screen)}"></div></body></html>"""

if (RAW / "mac").is_dir():
    with sync_playwright() as p:
        chrome = shutil.which("google-chrome")
        b = p.chromium.launch(executable_path=chrome) if chrome else p.chromium.launch()
        pg = b.new_page(viewport={"width": 2880, "height": 1800})
        for name, screen, h1, sub, theme in MAC_SLIDES:
            pg.set_content(mac_slide(screen, h1, sub, theme, name.endswith("hero"))); pg.wait_for_timeout(150)
            out = OUT / f"mac-{name}.png"
            pg.screenshot(path=str(out))
            Image.open(out).convert("RGB").save(out)
        b.close()
    print("mac done")
