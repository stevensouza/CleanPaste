# CleanPaste

A macOS menu bar app that pastes clipboard text with URLs stripped when you press **Cmd+Shift+V**.

Normal **Cmd+V** is completely untouched.

## What it strips

- Parenthesized URLs common in newsletters: `(https://example.com?utm_source=foo)`
- Bare URLs: `https://example.com/path`

### Example

Input:
> China's Ministry of Education (https://www.chinatalk.media/p/article?utm_source=test) released a white paper.

Cmd+Shift+V pastes:
> China's Ministry of Education released a white paper.

## Build & Install

```bash
cd CleanPaste
chmod +x build.sh
./build.sh
cp -r build/CleanPaste.app /Applications/
open /Applications/CleanPaste.app
```

## Permissions

On first launch macOS will prompt for **Accessibility** access — this is required for the global hotkey and the simulated paste. Go to:

> System Settings → Privacy & Security → Accessibility → enable CleanPaste

## Usage

| Key | Action |
|-----|--------|
| Cmd+V | Normal paste (unchanged) |
| Cmd+Shift+V | Paste with URLs stripped |

The ✂️ menu bar icon lets you toggle the feature on/off or run a test.
