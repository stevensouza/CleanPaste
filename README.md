# CleanPaste

A macOS menu bar app that pastes clipboard text with URLs stripped when you press **Cmd+Shift+V**.

Normal **Cmd+V** is completely untouched.

## What it strips

- Parenthesized URLs common in newsletters: `(https://example.com?utm_source=foo)`
- Bare URLs: `https://example.com/path`

### Example

Clipboard contents (copied from a newsletter):
> ChatGPT (https://help.openai.com/en/articles/20001153-using-chatgpt-in-carplay?utm_source=www.theneurondaily.com&utm_medium=referral&utm_campaign=ai-did-what-for-20k) now works in Apple CarPlay, so you can have a full voice conversation with it hands-free while you drive. Just connect your iPhone (iOS 26.4+) and tap New Voice Chat.

**Cmd+V** pastes the full text as-is (with the URL):
> ChatGPT (https://help.openai.com/en/articles/20001153-using-chatgpt-in-carplay?utm_source=www.theneurondaily.com&utm_medium=referral&utm_campaign=ai-did-what-for-20k) now works in Apple CarPlay, so you can have a full voice conversation with it hands-free while you drive. Just connect your iPhone (iOS 26.4+) and tap New Voice Chat.

**Cmd+Shift+V** pastes with the parenthesized URL stripped:
> ChatGPT now works in Apple CarPlay, so you can have a full voice conversation with it hands-free while you drive. Just connect your iPhone (iOS 26.4+) and tap New Voice Chat.

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
