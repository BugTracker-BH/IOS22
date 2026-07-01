# DisableWebViewStrongPassword

A rootless Theos tweak that disables the automatic **"Strong Password"** autofill
suggestion shown by `WKWebView` password fields, system-wide.

## Why the earlier attempt crash-looped Safari

Symptom: Safari endlessly reloads with *"This web page was reloaded because a
problem occurred."*

Cause: the tweak was injected into the WebKit **renderer** process
(`com.apple.WebKit.WebContent`) via a `com.apple.WebKit` bundle filter, and it
hooked `WKPreferences` inside that sandboxed process. That crashes the renderer,
which Safari respawns, which crashes again -> infinite reload.

Fix in this version:
- Filter on **`com.apple.UIKit` only**. The WebContent / Networking / GPU helper
  processes do **not** link UIKit, so they are never injected.
- Force `_allowsStrongPasswordSuggestions = NO` once, at `WKWebViewConfiguration`
  creation, in the **UI (app) process** where the property actually lives.
- No getter override, no `WKPreferences` hook, and all KVC is exception-guarded.

## Files

| File | Purpose |
|------|---------|
| `Tweak.x` | Logos hook on `WKWebViewConfiguration init` / `initWithCoder:` |
| `DisableWebViewStrongPassword.plist` | Substrate filter (UIKit apps only) |
| `Makefile` | Theos build config (arm64 + arm64e) |
| `control` | Package metadata |
| `.github/workflows/build.yml` | CI that builds the **rootless** `.deb` |

## Build locally

```sh
export THEOS=~/theos
make package THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1
# -> packages/com.yourname.disablewebviewstrongpassword_1.0.0_iphoneos-arm64.deb
```

For a rooted device instead, drop `THEOS_PACKAGE_SCHEME=rootless`.

## Build via GitHub Actions

Push to `main`, or run the **Build Rootless Package** workflow manually
(Actions tab -> Run workflow). The signed-off `.deb` is uploaded as the
`DisableWebViewStrongPassword-rootless-deb` artifact on the run.

## Install

Copy the `.deb` to the device and install with your package manager
(Sileo / Zebra), or:

```sh
dpkg -i com.yourname.disablewebviewstrongpassword_1.0.0_iphoneos-arm64.deb
killall -9 SpringBoard
```

## Compatibility

iOS 12 – iOS 17. The private selector is resolved at runtime, so an OS where it
is absent simply no-ops instead of crashing.
