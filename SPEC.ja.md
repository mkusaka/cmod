# Cmod — 仕様書

> English version: [SPEC.md](./SPEC.md)

## Overview

Cmod は macOS のメニューバーアプリケーションで、左右の Command キー単体タップをグローバルに監視して現在の入力ソースを切り替える。

eikana に着想を得ているが、最初のプロダクトスライスは意図的に小さく保つ。

- 左 Command 単体タップで英数入力へ切り替える
- 右 Command 単体タップでかな入力へ切り替える
- Command ショートカット、マウスクリック、左右 Command の重なり押しでは切り替えない
- Dock アイコンは表示せず、状態確認と設定はメニューバーから行う

## System Requirements

| 項目 | 要件 |
|------|------|
| OS | macOS 15.5+ |
| Xcode | CI / release build は 26.4+ |
| Swift | Swift compiler 6.3+ / Swift 6 language mode。ローカルの `swiftly` 利用は `.swift-version` で 6.3.1 に固定 |

## Architecture

### Tech Stack

| レイヤー | 技術 |
|---------|------|
| UI フレームワーク | SwiftUI (`SettingsView`) |
| アプリライフサイクル | AppKit (`NSApplicationDelegate`) |
| メニューバー | `NSStatusItem` + `NSMenu` |
| 設定ウィンドウ | 標準 `NSWindow` + `NSHostingController` |
| グローバルキー監視 | CoreGraphics listen-only `CGEventTap` |
| 権限状態 | ApplicationServices Accessibility API |
| 入力切り替え | CoreGraphics の合成キーボードイベント |
| JIS キーコード | Carbon.HIToolbox (`kVK_JIS_Eisu`, `kVK_JIS_Kana`) |
| 自動更新 | Sparkle 2 (`SPUStandardUpdaterController`) |
| 状態管理 | `ObservableObject` + `@Published` |

### App Configuration

| 項目 | 値 |
|------|-----|
| Bundle Identifier | `com.mkusaka.Cmod` |
| LSUIElement | `YES` (Dock 非表示) |
| メニューバーアイコン | 生成されたステータスアイコン (`StatusBarIcon.make()`) |
| Sparkle Feed | `https://mkusaka.github.io/cmod/appcast.xml` |
| リリース成果物 | `Cmod.zip` |

### ファイル構成

```
Cmod/
├── CmodApp.swift                  # SwiftUI エントリポイント
├── AppDelegate.swift              # AppKit ライフサイクル、accessory activation policy
├── MenuBarController.swift        # ステータスアイテムとメニューアクション
├── SettingsWindowController.swift # 標準設定ウィンドウ管理
├── SettingsView.swift             # 設定・状態タブ
├── CmodRuntime.swift              # 状態、権限、event tap、updater の runtime wiring
├── CmodState.swift                # 公開 runtime state
├── PermissionService.swift        # Accessibility trust status
├── GlobalCommandKeyEventTap.swift # listen-only global event tap
├── CommandKeyDetector.swift       # Command 単体タップの純粋な状態機械
├── InputSwitcher.swift            # JIS 英数/かな合成キーイベント
├── AppUpdaterController.swift     # Sparkle updater wrapper
├── BuildInfo.swift                # 表示用 version formatting
├── BuildInfo.generated.swift      # build-time 生成値の placeholder
├── ReleaseVersion.swift           # release tag -> numeric build version helper
└── Assets.xcassets/               # App icon と accent color

CmodTests/
└── CmodTests.swift                # Swift Testing によるユニットテスト

CmodUITests/
└── CmodUITests.swift              # XCTest による UI launch smoke test

Dependencies/
└── CmodSparkle/                   # Sparkle import 用のローカル Swift package wrapper
```

---

## Input Behavior

### Command Tap Detection

`CommandKeyDetector` は低レベルイベントサンプルから入力切り替え action を生成する純粋な状態機械。

```swift
struct CommandKeyDetector
```

| 入力シーケンス | 結果 |
|---------------|------|
| 左 Command down -> 左 Command up | `.switchToEnglish` |
| 右 Command down -> 右 Command up | `.switchToKana` |
| Command down -> 別キー down -> Command up | 何もしない |
| Command down -> マウスクリック -> Command up | 何もしない |
| 左右 Command の重なり押し | 何もしない |

detector は以下の状態を持つ。

| 状態 | 用途 |
|------|------|
| `leftCommandDown` | 左 Command が押下中かどうか |
| `rightCommandDown` | 右 Command が押下中かどうか |
| `candidateSide` | 単体タップ action になり得る Command 側 |
| `commandWasUsedWithOtherInput` | Command が他の入力と組み合わされたかどうか |

### Event Tap

`GlobalCommandKeyEventTap` は listen-only の session event tap をインストールする。

| Event Type | 処理 |
|------------|------|
| `.flagsChanged` | key code を Command side の状態遷移へ変換 |
| `.keyDown` | active な Command candidate を modified として扱う |
| `.leftMouseDown` / `.rightMouseDown` / `.otherMouseDown` | active な Command candidate を modified として扱う |
| `.tapDisabledByTimeout` / `.tapDisabledByUserInput` | event tap を再有効化 |

event tap はユーザー入力を消費・書き換えない。すべての callback で元の `CGEvent` を返す。

### Input Switching

`JISInputSwitcher` は合成 key down/up event を送出する。

| Action | 送出キー |
|--------|----------|
| `.switchToEnglish` | `kVK_JIS_Eisu` |
| `.switchToKana` | `kVK_JIS_Kana` |

合成イベントは `.cghidEventTap` に送出し、`event.flags = []` にすることで Command modifier を引き継がない。

---

## Runtime State

### CmodRuntime

`CmodRuntime` はアプリケーションサービスを束ねる `@MainActor` singleton。

| 依存 | 責務 |
|------|------|
| `CmodState` | monitoring、permission、last action の公開状態 |
| `PermissionService` | Accessibility trust status と prompt |
| `GlobalCommandKeyEventTap` | グローバル keyboard/mouse monitoring |
| `JISInputSwitcher` | 入力モード切り替え |
| `SettingsWindowController` | 設定ウィンドウ表示 |
| `AppUpdaterController` | Sparkle の起動と手動 update check |

起動時の流れ:

1. Accessibility status を prompt 付きで更新する。
2. Sparkle updater を開始する。
3. listen-only event tap を開始する。
4. monitoring active にするか、権限不足の message を表示する。

終了時の流れ:

1. event tap を停止・invalidate する。
2. event tap の run loop source を削除する。
3. monitoring inactive にする。

### CmodState

`CmodState` は runtime status の observable model。

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `accessibilityStatus` | `PermissionAccessState` | `granted`, `missing`, `unknown` |
| `monitoringActive` | `Bool` | event tap が active かどうか |
| `monitoringMessage` | `String` | monitoring 状態の説明 |
| `lastAction` | `InputModeAction?` | 最後に成功した入力切り替え |

ユーザー定義のキーマッピングは永続化しない。Sparkle の updater preferences は Sparkle 側が管理する。

---

## UI Components

### 1. メニューバー

メニューバーのステータスアイテムが主要な操作面。

**メニュー項目**:

| 項目 | 動作 |
|------|------|
| "About Cmod" | 標準 About panel を開き、version と short git hash を表示 |
| "Settings..." | 設定ウィンドウを開く |
| "Refresh Permission Status" | prompt 付きで Accessibility status を再確認 |
| "Monitoring: ..." | disabled の状態表示行 |
| "Accessibility: ..." | disabled の状態表示行 |
| "Last Switch: ..." | disabled の状態表示行 |
| "Check for Updates..." | Sparkle の手動 update check を開く |
| "Quit Cmod" | アプリを終了 |

### 2. 設定ウィンドウ

設定ウィンドウは標準 macOS `NSWindow`。

| 項目 | 値 |
|------|-----|
| サイズ | 500 x 320 pt |
| スタイル | `.titled`, `.closable`, `.miniaturizable` |
| タイトル | `Cmod Settings` |

#### General Tab

| コントロール | 動作 |
|-------------|------|
| "Automatically check for updates" | `SPUUpdater.automaticallyChecksForUpdates` を切り替える |
| "Automatically download updates" | `SPUUpdater.automaticallyDownloadsUpdates` を切り替える。自動確認が off の場合は disabled |
| "Check for Updates..." | Sparkle の手動 update check を開始 |

#### Status Tab

| フィールド | 値 |
|-----------|-----|
| Version | `BuildInfo.displayVersion` |
| Monitoring | `Active` または `Inactive` |
| Accessibility | `Granted`, `Missing`, `Unknown` |
| Last Switch | `English`, `Kana`, `None` |

このタブには prompt 付きで Accessibility status を再確認する "Refresh Permissions" ボタンも置く。

---

## Permissions

Cmod はグローバルキーボード監視と合成入力切り替えのために macOS 権限を必要とする。

| 権限 | 用途 |
|------|------|
| Accessibility | `AXIsProcessTrustedWithOptions` による trust check。event tap と合成キーイベントに必要になる場合がある |
| Input Monitoring | グローバルキーボードイベント監視時に macOS から要求される場合がある |

アプリが明示的に確認するのは Accessibility status。event tap を作れない場合、monitoring status は次の message になる。

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

- `@NSApplicationDelegateAdaptor` で `AppDelegate` をインストールする
- UI は AppKit 側で管理するため、SwiftUI Settings scene は `EmptyView`

### AppDelegate

| Lifecycle Method | 動作 |
|------------------|------|
| `applicationWillFinishLaunching` | activation policy を `.accessory` にする |
| `applicationDidFinishLaunching` | `MenuBarController` を作成し、`CmodRuntime` を開始 |
| `applicationWillTerminate` | runtime monitoring を停止 |

現在のスコープでは Dock アイコンも login item も持たない。

---

## Build Information

Xcode の build phase が build 時に `Cmod/BuildInfo.generated.swift` を書き込む。

| 値 | Source |
|----|--------|
| `gitCommitHash` | `git rev-parse --short HEAD` |
| `gitCommitHashFull` | `git rev-parse HEAD` |
| `version` | `MARKETING_VERSION`。未設定なら latest tag |

`BuildInfo.displayVersion` は次の形式で表示する。

```text
<version> (<short-git-hash>)
```

この値は About panel と Settings の Status tab に表示される。

---

## Testing

### Unit Tests

フレームワーク: Swift Testing (`@Test`, `#expect`)

| テスト領域 | 検証内容 |
|-----------|----------|
| Command tap detection | 左 Command tap で English に切り替わる |
| Command tap detection | 右 Command tap で Kana に切り替わる |
| Shortcut safety | Command shortcut では入力を切り替えない |
| Mouse safety | Command + mouse click では入力を切り替えない |
| Overlap safety | 左右 Command の重なり押しでは入力を切り替えない |
| Release versioning | semantic version tag から単調増加する numeric build version を作る |
| Build metadata | build info が version と git hash を持つ |
| UI launch | menu bar app として起動できる |

中核の入力挙動は `CommandKeyDetector` 経由でテストし、unit test では実際の global event tap をインストールしない。
UI test は menu bar app の起動 smoke test に限定する。

### Test Commands

```bash
xcodebuild -project Cmod.xcodeproj -scheme Cmod -destination 'platform=macOS' test
```

ユニットテストのみ:

```bash
xcodebuild -project Cmod.xcodeproj \
  -scheme Cmod \
  -destination 'platform=macOS' \
  -only-testing:CmodTests \
  test
```

UI smoke test のみ:

```bash
xcodebuild -project Cmod.xcodeproj \
  -scheme Cmod \
  -destination 'platform=macOS' \
  -only-testing:CmodUITests \
  test
```

local で UI smoke test を実行する前に、実行中の Cmod process は終了しておく。CI では UI test runner を Developer ID certificate なしで起動できるように、ad-hoc signing で実行する。

```bash
xcodebuild -project Cmod.xcodeproj \
  -scheme Cmod \
  -destination 'platform=macOS' \
  -derivedDataPath .build/CmodUITestDerivedData \
  -only-testing:CmodUITests \
  test \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=
```

---

## CI/CD

### Test Workflow

`.github/workflows/test.yml` は push、pull request、reusable `workflow_call` で実行する。

| Job | Runner | Checks |
|-----|--------|--------|
| `Lint` | `macos-26` | Xcode 26.4+, Swift 6.3 check, SwiftFormat, SwiftLint, actionlint, zizmor, pinact |
| `Unit Tests (macos-15)` | `macos-15` | `xcodebuild ... -only-testing:CmodTests test` |
| `Unit Tests (macos-26)` | `macos-26` | Xcode 26.4+, Swift 6.3 check, `xcodebuild ... -only-testing:CmodTests test` |
| `UI Tests (macos-26)` | `macos-26` | Xcode 26.4+, Swift 6.3 check, ad-hoc signed `xcodebuild ... -only-testing:CmodUITests test` |

### Release Workflow

`.github/workflows/release.yml` は `v*` tag と manual dispatch で実行する。

release flow:

1. shared `Test` workflow を実行する。
2. Developer ID signed app を archive / export する。
3. notarize して staple する。
4. tag push 時は GitHub Releases に `Cmod.zip` を upload する。
5. `mkusaka/homebrew-tap` に Homebrew cask update を dispatch する。
6. ZIP を Sparkle EdDSA で署名する。
7. `gh-pages` branch に `appcast.xml` を deploy する。

manual `workflow_dispatch` は signing、notarization、export を検証するが、GitHub Release、Homebrew、Sparkle artifact は publish しない。

---

## Dependencies

| Dependency | 用途 |
|------------|------|
| Sparkle 2 | update check と appcast 連携 |
| CmodSparkle | Sparkle import 用のローカル Swift package wrapper |
| SwiftFormat | formatting |
| SwiftLint | Swift linting |
| actionlint | GitHub Actions linting |
| zizmor | GitHub Actions security linting |
| pinact | GitHub Actions pinning check |
| lefthook | 任意の local pre-commit hook runner |

---

## Known Limitations

- 入力マッピングは固定: 左 Command -> English、右 Command -> Kana。
- 実装済みの切り替えは JIS 英数/かなのみ。
- login item support はまだ実装していない。
- key customization UI はまだ実装していない。
- 権限回復後は、ユーザーが macOS Settings で許可したうえで restart または status refresh する必要がある。
- event tap は listen-only のため、元の Command key event が他アプリに届くことは防げない。

## License

MIT
