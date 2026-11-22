# Darkroom

A small, private photo-grading app with film looks: Fujifilm-inspired and Hollywood-inspired.
I built it for my Canon 4000D, but it works with any JPG, PNG or Canon CR2.

Everything runs on your computer, on the GPU (WebGL2). No uploads, no account, no tracking.

## Download

**Mac:** [**Download Darkroom for Mac**](https://github.com/hmimiaymane-scarface/darkroom-film-looks/releases/latest/download/Darkroom-1.0.0-mac.zip) (works on Apple silicon and Intel, macOS 12 or later)

1. Unzip it and drag **Darkroom** into your **Applications** folder.
2. Open it. The first time, macOS says it can't verify the developer (the app isn't registered with Apple's paid program).
   Click **Done**, then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.
   You only need to do this once.

**Windows:** [**Download Darkroom for Windows**](https://github.com/hmimiaymane-scarface/darkroom-film-looks/releases/latest/download/Darkroom-Setup-1.0.0.exe) (Windows 10 and 11)

1. Run **Darkroom-Setup-1.0.0.exe**. It installs in a few seconds (no admin rights needed) and adds Darkroom to your Start menu and desktop.
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

## LUTs

**Use any LUT:** click **+ Add LUT** under *My LUTs* (or drag a `.cube` file onto the window).
It appears next to the built-in looks, and the strength, grain, glow and vignette sliders work on top of it.
Your LUTs are remembered. Remove one with the × on its tile (the file on your computer is not touched).

**Take the looks elsewhere:** click **Save looks as LUT files** to get every built-in look as a `.cube`
file for Lightroom, Photoshop, VSCO, Capture One and other editors. (Grain, glow and vignette can't be
stored in a LUT, so those stay in Darkroom.)

## Features

- Live preview with look **strength**, exposure, contrast, warmth, tint, saturation, **film grain**, **halation glow** and vignette
- Before/after split (`\`) and hold `B` to see the original
- Undo / redo, plus per-photo edits that are **remembered** when you reopen a photo
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

## Tip for Canon shooters

Set your camera's Picture Style to **Neutral** (contrast and saturation turned down a notch).
Flat files give the looks more room to work.

## Project layout

```
darkroom.html      the whole app: UI, WebGL shader, looks, export
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
