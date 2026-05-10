# Cmod — Specification

> Japanese version: [SPEC.ja.md](./SPEC.ja.md)

## Overview

Cmod is a minimal macOS menu bar application that switches the current input source by watching global taps of the left and right Command keys.

The app is inspired by eikana, but intentionally keeps the first product slice small:

- Left Command tap switches to English input
- Right Command tap switches to Kana input
- Command shortcuts, mouse clicks, and overlapping Command keys are ignored
- There is no Dock icon; status and settings are available from the menu bar

## System Requirements

| Item | Requirement |
|------|-------------|
| OS | macOS 15.5+ |
| Xcode | 16+ |
| Swift | 5.0 |

## Architecture

### Tech Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI (`SettingsView`) |
| App Lifecycle | AppKit (`NSApplicationDelegate`) |
| Menu Bar | `NSStatusItem` + `NSMenu` |
| Settings Window | Standard `NSWindow` with `NSHostingController` |
| Global Key Monitoring | CoreGraphics listen-only `CGEventTap` |
| Permission Status | ApplicationServices Accessibility API |
| Input Switching | CoreGraphics synthetic keyboard events |
| JIS Key Codes | Carbon.HIToolbox (`kVK_JIS_Eisu`, `kVK_JIS_Kana`) |
| Updates | Sparkle 2 via `SPUStandardUpdaterController` |
| State Management | `ObservableObject` + `@Published` |

### App Configuration

| Item | Value |
|------|-------|
| Bundle Identifier | `com.mkusaka.Cmod` |
| LSUIElement | `YES` (hidden from Dock) |
| Menu Bar Icon | Generated app status icon (`StatusBarIcon.make()`) |
| Sparkle Feed | `https://mkusaka.github.io/cmod/appcast.xml` |
| Release Artifact | `Cmod.zip` |

### File Structure

```
Cmod/
├── CmodApp.swift                  # SwiftUI entry point
├── AppDelegate.swift              # AppKit lifecycle, accessory activation policy
├── MenuBarController.swift        # Status item and menu actions
├── SettingsWindowController.swift # Standard settings window management
├── SettingsView.swift             # Settings and status tabs
├── CmodRuntime.swift              # Runtime wiring for state, permissions, event tap, updater
├── CmodState.swift                # Published runtime state
├── PermissionService.swift        # Accessibility trust status
├── GlobalCommandKeyEventTap.swift # Listen-only global event tap
├── CommandKeyDetector.swift       # Pure command tap state machine
├── InputSwitcher.swift            # JIS Eisu/Kana synthetic key events
├── AppUpdaterController.swift     # Sparkle updater wrapper
├── BuildInfo.swift                # Display version formatting
├── BuildInfo.generated.swift      # Build-time generated version/hash placeholders
├── ReleaseVersion.swift           # Release tag -> numeric build version helper
└── Assets.xcassets/               # App icon and accent color

CmodTests/
└── CmodTests.swift                # Unit tests using Swift Testing

Dependencies/
└── CmodSparkle/                   # Local Swift package wrapper for Sparkle imports
```

---

## Input Behavior

### Command Tap Detection

`CommandKeyDetector` is the pure state machine that converts low-level samples into input switching actions.

```swift
struct CommandKeyDetector
```

| Input Sequence | Result |
|----------------|--------|
| Left Command down -> Left Command up | `.switchToEnglish` |
| Right Command down -> Right Command up | `.switchToKana` |
| Command down -> another key down -> Command up | No action |
| Command down -> mouse click -> Command up | No action |
| Left and right Command overlap | No action |

The detector tracks:

| State | Purpose |
|-------|---------|
| `leftCommandDown` | Whether the left Command key is currently held |
| `rightCommandDown` | Whether the right Command key is currently held |
| `candidateSide` | The Command key that may become a tap action |
| `commandWasUsedWithOtherInput` | Whether the Command key was combined with another input |

### Event Tap

`GlobalCommandKeyEventTap` installs a listen-only session event tap.

| Event Type | Handling |
|------------|----------|
| `.flagsChanged` | Converts key code into Command side state transitions |
| `.keyDown` | Marks the active Command candidate as modified |
| `.leftMouseDown` / `.rightMouseDown` / `.otherMouseDown` | Marks the active Command candidate as modified |
| `.tapDisabledByTimeout` / `.tapDisabledByUserInput` | Re-enables the event tap |

The event tap does not consume or rewrite user input. It returns the original `CGEvent` for every callback.

### Input Switching

`JISInputSwitcher` posts synthetic key down/up events:

| Action | Posted Key |
|--------|------------|
| `.switchToEnglish` | `kVK_JIS_Eisu` |
| `.switchToKana` | `kVK_JIS_Kana` |

Synthetic events are posted to `.cghidEventTap` with empty flags so the switch action does not inherit the Command modifier.

---

## Runtime State

### CmodRuntime

`CmodRuntime` is a `@MainActor` singleton that wires together the application services.

| Dependency | Responsibility |
|------------|----------------|
| `CmodState` | Published monitoring, permission, and last-action state |
| `PermissionService` | Accessibility trust status and prompt |
| `GlobalCommandKeyEventTap` | Global keyboard and mouse monitoring |
| `JISInputSwitcher` | Input mode switching |
| `SettingsWindowController` | Settings window presentation |
| `AppUpdaterController` | Sparkle startup and manual update checks |

Startup flow:

1. Refresh Accessibility status with prompting enabled.
2. Start Sparkle updater.
3. Start the global listen-only event tap.
4. Mark monitoring active or show the permission failure message.

Shutdown flow:

1. Stop and invalidate the event tap.
2. Remove the event tap run loop source.
3. Mark monitoring inactive.

### CmodState

`CmodState` is the observable runtime status model.

| Property | Type | Description |
|----------|------|-------------|
| `accessibilityStatus` | `PermissionAccessState` | `granted`, `missing`, or `unknown` |
| `monitoringActive` | `Bool` | Whether the event tap is active |
| `monitoringMessage` | `String` | Human-readable monitoring status |
| `lastAction` | `InputModeAction?` | Last successful input switch |

No user-defined key mappings are persisted. Sparkle manages its own updater preferences.

---

## UI Components

### 1. Menu Bar

The menu bar status item is the primary control surface.

**Menu Items**:

| Item | Behavior |
|------|----------|
| "About Cmod" | Opens the standard About panel with version and short git hash |
| "Settings..." | Opens the settings window |
| "Refresh Permission Status" | Re-checks Accessibility status with prompt enabled |
| "Monitoring: ..." | Disabled status row |
| "Accessibility: ..." | Disabled status row |
| "Last Switch: ..." | Disabled status row |
| "Check for Updates..." | Opens Sparkle update check |
| "Quit Cmod" | Terminates the app |

### 2. Settings Window

The settings window is a standard macOS `NSWindow`.

| Item | Value |
|------|-------|
| Size | 500 x 320 pt |
| Style | `.titled`, `.closable`, `.miniaturizable` |
| Title | `Cmod Settings` |

#### General Tab

| Control | Behavior |
|---------|----------|
| "Automatically check for updates" | Toggles `SPUUpdater.automaticallyChecksForUpdates` |
| "Automatically download updates" | Toggles `SPUUpdater.automaticallyDownloadsUpdates`; disabled when automatic checks are off |
| "Check for Updates..." | Starts Sparkle manual update check |

#### Status Tab

| Field | Value |
|-------|-------|
| Version | `BuildInfo.displayVersion` |
| Monitoring | `Active` or `Inactive` |
| Accessibility | `Granted`, `Missing`, or `Unknown` |
| Last Switch | `English`, `Kana`, or `None` |

The tab also includes a "Refresh Permissions" button that re-checks Accessibility status with prompting enabled.

---

## Permissions

Cmod needs macOS permission for global keyboard monitoring and synthetic input switching.

| Permission | Usage |
|------------|-------|
| Accessibility | Trust check via `AXIsProcessTrustedWithOptions`; may be required for event tap and posted key events |
| Input Monitoring | May be requested by macOS for global keyboard event monitoring |

The app explicitly checks Accessibility status. If the event tap cannot be created, the monitoring status is set to:

```text
Keyboard monitoring is unavailable. Check Input Monitoring and Accessibility permissions.
```

---

## Application Lifecycle

### CmodApp

```swift
@main
@MainActor
struct CmodApp: App
```

- Installs `AppDelegate` through `@NSApplicationDelegateAdaptor`
- Provides an empty SwiftUI Settings scene because UI is managed by AppKit

### AppDelegate

| Lifecycle Method | Behavior |
|------------------|----------|
| `applicationWillFinishLaunching` | Sets activation policy to `.accessory` |
| `applicationDidFinishLaunching` | Creates `MenuBarController` and starts `CmodRuntime` |
| `applicationWillTerminate` | Stops runtime monitoring |

There is no Dock icon and no login item in the current scope.

---

## Build Information

The Xcode build phase writes `Cmod/BuildInfo.generated.swift` at build time.

| Value | Source |
|-------|--------|
| `gitCommitHash` | `git rev-parse --short HEAD` |
| `gitCommitHashFull` | `git rev-parse HEAD` |
| `version` | `MARKETING_VERSION`, falling back to latest tag |

`BuildInfo.displayVersion` renders:

```text
<version> (<short-git-hash>)
```

This value is shown in the About panel and the Settings status tab.

---

## Testing

### Unit Tests

Framework: Swift Testing (`@Test`, `#expect`)

| Test Area | Verified Behavior |
|-----------|-------------------|
| Command tap detection | Left Command tap switches to English |
| Command tap detection | Right Command tap switches to Kana |
| Shortcut safety | Command shortcuts do not switch input |
| Mouse safety | Command + mouse click does not switch input |
| Overlap safety | Overlapping Command keys do not switch input |
| Release versioning | Semantic version tags produce monotonic numeric build versions |
| Build metadata | Build info contains version and git hash |

The core input behavior is tested through `CommandKeyDetector`, avoiding a real global event tap in unit tests.

### Test Commands

```bash
xcodebuild -project Cmod.xcodeproj -scheme Cmod -destination 'platform=macOS' test
```

For unit tests only:

```bash
xcodebuild -project Cmod.xcodeproj \
  -scheme Cmod \
  -destination 'platform=macOS' \
  -only-testing:CmodTests \
  test
```

---

## CI/CD

### Test Workflow

`.github/workflows/test.yml` runs on push, pull request, and reusable `workflow_call`.

| Job | Runner | Checks |
|-----|--------|--------|
| `Lint` | `macos-15` | SwiftFormat, SwiftLint, actionlint, zizmor, pinact |
| `Unit Tests (macos-15)` | `macos-15` | `xcodebuild ... -only-testing:CmodTests test` |
| `Unit Tests (macos-26)` | `macos-26` | `xcodebuild ... -only-testing:CmodTests test` |

### Release Workflow

`.github/workflows/release.yml` runs on `v*` tags and manual dispatch.

Release flow:

1. Run the shared `Test` workflow.
2. Archive and export a Developer ID signed app.
3. Notarize and staple the app.
4. Upload `Cmod.zip` to GitHub Releases for tag pushes.
5. Dispatch the Homebrew cask update to `mkusaka/homebrew-tap`.
6. Sign the ZIP with Sparkle EdDSA.
7. Deploy `appcast.xml` to the `gh-pages` branch.

Manual `workflow_dispatch` runs validate signing, notarization, and export without publishing GitHub Release, Homebrew, or Sparkle artifacts.

---

## Dependencies

| Dependency | Purpose |
|------------|---------|
| Sparkle 2 | Update checks and appcast integration |
| CmodSparkle | Local Swift package wrapper for Sparkle imports |
| SwiftFormat | Formatting |
| SwiftLint | Swift linting |
| actionlint | GitHub Actions linting |
| zizmor | GitHub Actions security linting |
| pinact | GitHub Actions pinning check |
| lefthook | Optional local pre-commit hook runner |

---

## Known Limitations

- Input mappings are fixed: left Command -> English, right Command -> Kana.
- Only JIS Eisu/Kana switching is implemented.
- No login item support is implemented yet.
- No per-key customization UI is implemented yet.
- Permission recovery still requires the user to approve macOS settings and restart or refresh status manually.
- The event tap is listen-only, so Cmod cannot prevent the original Command key event from reaching other apps.

## License

MIT
