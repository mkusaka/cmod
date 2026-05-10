# Cmod

Cmod is a minimal macOS menu bar app inspired by eikana.

It watches left and right Command key taps globally:

- Left Command tap: switch to English input
- Right Command tap: switch to Kana input
- Command shortcuts, mouse clicks, and overlapping Command keys are ignored

The app intentionally keeps the first slice small: no login item and no per-key
customization yet. Settings are available from the menu bar.

## Install

### Homebrew

```bash
brew install --cask mkusaka/tap/cmod
```

The Homebrew cask is updated by the release workflow after a tagged release is
published.

### Manual Download

Download the latest `Cmod.zip` from [GitHub Releases](https://github.com/mkusaka/cmod/releases),
extract it, and move `Cmod.app` to `/Applications`.

## Permissions

Cmod needs macOS permissions before global key monitoring can work:

- Accessibility
- Input Monitoring, if macOS asks for it

After granting permissions, restart Cmod from the menu bar item or launch it
again from Finder.

## Architecture

Cmod uses native macOS APIs directly:

- `SwiftUI`: settings window and previews
- `AppKit`: app lifecycle and menu bar item
- `CoreGraphics`: listen-only event tap for global keyboard/mouse events
- `ApplicationServices`: Accessibility trust prompt/status
- `Carbon.HIToolbox`: JIS virtual key codes for Eisu and Kana
- `Sparkle`: in-app update checks against a signed appcast feed

Runtime shape:

```text
CmodApp
├─ AppDelegate
├─ MenuBarController
├─ SettingsWindowController
├─ AppUpdaterController
├─ CmodRuntime
├─ BuildInfo
├─ PermissionService
├─ GlobalCommandKeyEventTap
├─ CommandKeyDetector
└─ JISInputSwitcher
```

The About panel and Settings status tab show the build version together with the
short Git commit hash generated at build time.

`CommandKeyDetector` is isolated as pure logic so the key behavior can be unit
tested without installing a global event tap. `CmodUITests` covers a minimal
launch smoke test for the menu bar app on CI.

## Build

CI and release builds target Xcode 26.2 with the Swift 6.2 compiler. The
project itself uses Swift 6 language mode (`SWIFT_VERSION = 6.0`), and
`.swift-version` pins local CLI tool usage to Swift 6.2.3 when using `swiftly`.

```bash
swiftly install 6.2.3
swiftly use 6.2.3
swiftly run swift --version
```

```bash
xcodebuild -project Cmod.xcodeproj -scheme Cmod -destination 'platform=macOS' build
```

Run the locally built app:

```bash
open -n "$(xcodebuild -project Cmod.xcodeproj -scheme Cmod -configuration Debug -showBuildSettings 2>/dev/null | awk -F' = ' '/BUILT_PRODUCTS_DIR/ {print $2; exit}')/Cmod.app"
```

## Test

```bash
xcodebuild -project Cmod.xcodeproj -scheme Cmod -destination 'platform=macOS' test
```

Run only the UI smoke test. Quit any running Cmod process first so XCTest does
not attach to an already-running app with the same bundle identifier.

```bash
xcodebuild -project Cmod.xcodeproj -scheme Cmod -destination 'platform=macOS' -only-testing:CmodUITests test
```

CI runs the UI smoke test with ad-hoc signing so the UI test runner can launch
without a Developer ID certificate. When reproducing that locally, use a
separate DerivedData path so the normal Debug app signing stays untouched:

```bash
xcodebuild -project Cmod.xcodeproj -scheme Cmod -destination 'platform=macOS' -derivedDataPath .build/CmodUITestDerivedData -only-testing:CmodUITests test CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=
```

## Lint and Format

Tool versions are managed by `mise.toml`.

```bash
mise install
mise exec -- swiftformat .
mise exec -- swiftlint lint --quiet
mise exec -- actionlint
mise exec -- zizmor --offline .
mise exec -- pinact run --check
```

Update pinned GitHub Actions manually when needed:

```bash
mise exec -- pinact run -u
```

Install the optional pre-commit hooks:

```bash
mise exec -- lefthook install
```

## Icon

The app icon is generated from a checked-in Swift script:

```bash
scripts/generate_icon.swift Cmod/Assets.xcassets/AppIcon.appiconset
```

## Release Automation

Signed releases use a locally exported `Developer ID Application` certificate
together with an App Store Connect API key for `notarytool`.

Required GitHub repository secrets:

- `APPLE_TEAM_ID`: Apple Developer Team ID
- `APPLE_DEVELOPER_ID_P12_BASE64`: Base64-encoded `Developer ID Application` certificate exported as `.p12`
- `APPLE_DEVELOPER_ID_P12_PASSWORD`: Password used when exporting the `.p12`
- `APPLE_KEYCHAIN_PASSWORD`: Random password used for the temporary GitHub Actions keychain
- `APPLE_APP_STORE_CONNECT_API_KEY_BASE64`: Base64-encoded App Store Connect API key (`.p8`) used for `notarytool`
- `APPLE_APP_STORE_CONNECT_KEY_ID`: App Store Connect API key ID
- `APPLE_APP_STORE_CONNECT_ISSUER_ID`: App Store Connect issuer ID
- `HOMEBREW_TAP_TOKEN`: GitHub token with permission to dispatch updates to `mkusaka/homebrew-tap`
- `SPARKLE_ED_PRIVATE_KEY`: Sparkle EdDSA private key used to sign release ZIPs for appcast delivery

The release workflow:

- Runs lint and unit tests first
- Archives and exports a `Developer ID` signed app
- Notarizes and staples the app
- Uploads `Cmod.zip` to GitHub Releases for tag pushes
- Dispatches a cask update to `mkusaka/homebrew-tap`
- Signs the release ZIP with Sparkle EdDSA and deploys `appcast.xml` to the `gh-pages` branch

Manual validation runs are supported through `workflow_dispatch`. They require
signing secrets but skip GitHub Release creation, Homebrew tap updates, and
Sparkle appcast publishing.

### How To Cut A Release

1. Merge the release target changes into `main` and confirm the `Test` workflow is green.
2. Create and push a semantic version tag.

```bash
VERSION=0.0.1
git tag "v${VERSION}"
git push origin "v${VERSION}"
```

3. Watch the `Release` workflow that was triggered by the tag push.

```bash
gh run list --workflow Release --limit 5
gh run watch
```

4. Verify that the workflow produced the downstream artifacts.

```bash
gh release view "v${VERSION}"
brew update
brew info --cask mkusaka/tap/cmod
curl -fsSL https://mkusaka.github.io/cmod/appcast.xml | rg "<sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>"
```

Expected results:

- a signed and notarized `Cmod.zip` attached to the GitHub Release
- a cask update dispatch to `mkusaka/homebrew-tap`
- an appcast entry on GitHub Pages for Sparkle updates

The workflow derives the release version from the tag name, so repository files
do not need a manual version bump just for release publication.

Sparkle compares updates using `CFBundleVersion` / `sparkle:version`, not the
human-readable `CFBundleShortVersionString`. The workflow derives the numeric
build version from tags such as `0.0.1` so app updates remain monotonic.

For Sparkle to work in production, GitHub Pages must be enabled for this
repository and configured to serve from the `gh-pages` branch. `SUPublicEDKey`
is currently set in `Config/Cmod-Info.plist` to match the Tabora-style
`SPARKLE_ED_PRIVATE_KEY` secret. If Cmod gets its own Sparkle key later, update
both values together.

### How To Run A Validation Build

Use `workflow_dispatch` on the `Release` workflow when you want to validate
signing, notarization, and export without publishing a GitHub Release or
updating Homebrew.

```bash
gh workflow run Release --field version=0.0.1
gh run list --workflow Release --limit 5
gh run watch
```
