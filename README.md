# Darkroom

A small, private photo-grading app with film looks: Fujifilm-inspired and Hollywood-inspired.
I built it for my Canon 4000D, but it works with any JPG, PNG or Canon CR2.

Everything runs on your computer, on the GPU (WebGL2). No uploads, no account, no tracking.

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
```

### Adding your own look

Looks are plain data in the `LOOKS` array in `darkroom.html`. Each one can set saturation, contrast,
fade, shadow/highlight tints, lift/gamma/gain, a 3×3 channel mixer, and per-hue saturation, hue shift
and brightness for six colour bands. Copy an existing look and tweak it.

## License

MIT. See [LICENSE](LICENSE).
