# Contributing to Darkroom

Thanks for helping! There are two ways to contribute, and the first needs no coding at all.

## Share a look (no coding needed)

1. In Darkroom, pick a look and fine-tune it in the **Edit** tab (light, colour mixer, curves, colour grading, effects).
2. Click **Save as My Look** and give it a name.
3. Hover over your look under **My Looks** and click **⤓** to save it as a `.darkroom` file.
4. Add that file to the [`community-looks/`](community-looks) folder with a pull request
   (on GitHub: open the folder → **Add file → Upload files**), and add one line to its README table.

Please include a before/after image in the pull request so others can see the look.

## Improve the app

Darkroom is deliberately simple to work on:

| File | What it is |
|---|---|
| `darkroom.html` | The whole editor: UI, WebGL2 shader, looks, export. No build step, no dependencies. Open it in a browser to run it. |
| `mac/` | Native macOS app (Swift, AppKit + WebKit). Build with `mac/build.sh`. |
| `windows/` | Windows app (Electron). Build with `cd windows && npm install && npm run build`. |

### Adding a built-in look

Built-in looks live in the `LOOKS` array in `darkroom.html`. Each is a few numbers: saturation, contrast,
fade, shadow/highlight tints, lift/gamma/gain, a 3×3 channel mixer, and saturation / hue / brightness for six
colour bands. Copy an existing look, change the values, and reload the page to see it.

### Guidelines

- Keep it easy for non-technical people: sensible defaults, plain-language labels, nothing that needs a manual.
- Keep everything local: no network requests, accounts or tracking.
- Keep `darkroom.html` dependency-free so it still works as a single file.
- Test in Chrome and Safari before opening a pull request.

### Good first issues

Look for the [`good first issue`](../../labels/good%20first%20issue) label on GitHub.

By contributing you agree your work is released under the [MIT License](LICENSE).
