# Darkroom

A small, private photo editor with film looks (Fujifilm-, Kodak- and Hollywood-inspired) and the editing tools to make them your own.
Works with JPG, PNG and Canon CR2 files from any camera.

Everything runs on your computer, on the GPU (WebGL2). No uploads, no account, no tracking.

## Download

**Mac:** [**Download Darkroom for Mac**](https://github.com/hmimiaymane-scarface/darkroom-film-looks/releases/latest/download/Darkroom-mac.zip) (works on Apple silicon and Intel, macOS 12 or later)

1. Unzip it and drag **Darkroom** into your **Applications** folder.
2. Open it. The first time, macOS says it can't verify the developer (the app isn't registered with Apple's paid program).
   Click **Done**, then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.
   You only need to do this once.

**Windows:** [**Download Darkroom for Windows**](https://github.com/hmimiaymane-scarface/darkroom-film-looks/releases/latest/download/Darkroom-Windows-Setup.exe) (Windows 10 and 11)

1. Run **Darkroom-Windows-Setup.exe**. It installs in a few seconds (no admin rights needed) and adds Darkroom to your Start menu and desktop.
2. If Windows shows **"Windows protected your PC"** (it does this for new apps that aren't commercially code-signed), click **More info → Run anyway**. Only needed once.

**Linux / any computer:** download [`darkroom.html`](https://github.com/hmimiaymane-scarface/darkroom-film-looks/releases/latest/download/darkroom.html)
and open it in Chrome or Edge. It's the same editor in a single file.

## Looks (38 built in)

| Group | Looks |
|---|---|
| **Fuji-inspired** | Chrome Classic, Vivid Slide, Nostalgic Neg, Cine Soft, Portrait Soft, Street 400, Pastel 400, Natural Ace |
| **Kodak-inspired** | Portrait 400, Portrait 160, Golden 200, Vivid 100, Clean Slide, Heritage 64, Tungsten 800, Cinema 500T |
| **Hollywood-inspired** | Blockbuster, Epic Natural, Cinema Print, Cold Thriller, Code Green, Pastel Symmetry, Parisian Dream, Orange Haze, Desert Gold, Border Heat, Moonlight, Neon Noir, Day for Night, Bleach Bypass, Seventies |
| **Black & White** | Mono Fine, Push 400, Soft Silver, Red Filter, Film Noir, Sepia Print |

Hover over any look in the app to see what inspired it (e.g. *Portrait 400: inspired by Kodak Portra 400*).

These looks are original approximations, *inspired by* well-known film stocks and movie grades.
They are not affiliated with or endorsed by Fujifilm, Kodak or any studio.

## Editing

Pick a look in the **Looks** tab, then fine-tune it in the **Edit** tab:

| Section | What you get |
|---|---|
| **Crop & Rotate** | Crop with Original, Free, 1:1, 4:5, 3:2 and 16:9 frames, rotate 90°, flip, and straighten (auto-crops so no empty corners) |
| **Light** | Exposure, Contrast, Highlights, Shadows, Whites, Blacks |
| **Color** | White balance picker (click something grey), Warmth, Tint, Saturation |
| **Color Mixer** | Hue, saturation and luminance for 8 colours, plus a picker: click a colour in the photo to adjust it |
| **Curves** | RGB and per-channel tone curves over a histogram |
| **Color Grading** | Shadows / midtones / highlights colour wheels with brightness |
| **Effects** | Clarity, Sharpen, Film grain, Halation glow, Vignette |

Everything is non-destructive, with undo/redo, and your edits are remembered per photo.

## My Looks

- **Save as My Look** (Edit tab) saves the current look with all your edits, so you can apply it to any photo in one click.
- **Share it:** hover over your look and click **⤓** to save a small `.darkroom` file. Anyone can drop it into Darkroom to use it.
- **Community looks:** ready-made looks from Darkroom users live in [`community-looks/`](community-looks). Add yours: see [CONTRIBUTING.md](CONTRIBUTING.md).

## LUTs

**Use any LUT:** click **Import LUT or look** under *My Looks* (or drag a `.cube` file onto the window).
It appears next to the built-in looks, and every Edit tool works on top of it.
Remove one with the × on its tile (the file on your computer is not touched).

**Take your colour elsewhere:** **Save looks as LUT files** exports every built-in look as a `.cube`, and
**Export as LUT** (Edit tab) saves your own edit as one, for Lightroom, Photoshop, DaVinci Resolve, VSCO and more.
Crop, clarity, sharpen, grain, glow and vignette can't be stored in a LUT, so those stay in Darkroom.

## Also

- Before/after split (`\`) and hold `B` to see the original
- Batch export to full size, 3840, 2048 or 1080 px, **keeping camera EXIF** (date, lens, settings)
- Canon **CR2**: uses the full-size JPEG the camera embeds in the RAW file (not a true RAW develop)

## Run it

**Mac app:** build it once (needs Xcode Command Line Tools: `xcode-select --install`):

```bash
mac/build.sh
```

Then drag `build/Darkroom.app` into **Applications**. You can open photos with ⌘O, by dropping
them on the window or Dock icon, or with right-click → Open With → Darkroom.

**Windows app:** build the installer from macOS, Linux or Windows (needs Node.js):

```bash
cd windows && npm install && npm run build
```

The installer lands in `windows/dist/`. Use `npm start` to run the app without installing it.

**Any browser:** just open `darkroom.html` in Chrome, Edge or Safari. It's a single self-contained file.

## Shooting tip

Set your camera's picture profile to **Neutral** (on Canon: Picture Style → Neutral) (contrast and saturation turned down a notch).
Flat files give the looks more room to work.

## Project layout

```
darkroom.html      the whole app: UI, WebGL shader, looks, export
community-looks/   shared .darkroom looks
mac/main.swift     native macOS shell (WKWebView, menus, file open/save)
mac/Info.plist     app bundle metadata
mac/icon.swift     draws the app icon
mac/build.sh       builds build/Darkroom.app (universal binary)
windows/main.js    Windows app (Electron): window, menus, file open/save
windows/build.mjs  builds the Windows installer (no Wine needed)
```

### Adding your own look

Looks are plain data in the `LOOKS` array in `darkroom.html`. Each one can set saturation, contrast,
fade, shadow/highlight tints, lift/gamma/gain, a 3×3 channel mixer, and per-hue saturation, hue shift
and brightness for six colour bands. Copy an existing look and tweak it.

## License

MIT. See [LICENSE](LICENSE).
