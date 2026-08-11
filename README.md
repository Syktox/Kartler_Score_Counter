# Kartler

A Flutter app for tracking scores at card game nights. Besides a free counter, Kartler includes scoring modes for Watten, Mulatschak and Hosn Obe, with a German user interface. Game state, global players, match history and settings are stored locally on the device.

This repository contains the source code, assets, and configuration. Generated Flutter artifacts and platform-specific build outputs are recreated locally.

## Features

- Four modes in one app: `Zähler` (free counter), `Watten`, `Mulatschak`, and `Hosn Obe`
- Global player profiles shared across all modes
- Local persistence for all values via `shared_preferences`
- Undo and redo support for the most recent actions
- Drawer-based management for creating, selecting, renaming, deleting, and reordering items
- Game sessions („Spielabende“) with match history, summaries, and statistics
- Settings for app mode, theme, rule profile, haptics, and history
- Platform folders included for Android, iOS, Web, Windows, Linux, and macOS

## Modes

### Zähler (Counter)

- Manage multiple counters
- Add, rename, delete, and reorder counters
- Track values with `+`, `-`, and `Reset`
- Optional history of the last changes, undoable per counter

### Watten

- One active game at a time: `Neues Spiel` records the finished game into the statistics and starts a fresh one at `0:0`
- Separate score tracking for `Wir` (us) and `Die` (them)
- Quick scoring buttons for `+2` and `+3`
- Reset only the currently selected side
- Winner banner when a side reaches the configurable winning score
- Optional table mode for landscape: both sides face each other, ideal when the phone lies on the table

### Mulatschak

- Players selected directly from the player cards
- Score controls for `-5`, `-1`, `+1`, `+5`, plus a `2x`–`16x` multiplier
- History grouped per completed round, undoable
- Optional Muleqack reset: a player is automatically reset to a configurable value once a threshold is reached
- Winner banner when a player reaches `0` points

### Hosn Obe

- Each player starts with a configurable number of lives
- The last player with lives remaining wins
- Reset restores all players to the starting lives

## Usage

1. Open the drawer from the menu in the app bar.
2. Select a counter, game, or player, or create a new one.
3. Adjust the current value using the controls for the active mode.
4. Use `Undo` and `Redo` to revert or reapply the most recent actions.
5. Start a game session („Spielabend starten“) and record matches after each round.
6. Open `Einstellungen` to change the mode, theme, rule profile, and history options.

## Requirements

- Flutter SDK
- Dart SDK compatible with the Flutter version used by the project
- Xcode for iOS and macOS builds on macOS
- For Android builds, a JDK 17 or newer (Gradle 9.1, AGP 9.0.1, built-in Kotlin); when building on Java 25 the build prints JDK native-access warnings that do not affect the result

## Play Store Requirements

Android release builds are configured in [android/app/build.gradle.kts](android/app/build.gradle.kts):

- Application ID: `com.raysix.kartler`
- `compileSdk`: `36`
- `targetSdk`: `36`
- Release signing uses `android/key.properties` when a local or CI keystore is available.

For Google Play distribution, build and upload the Android App Bundle:

```bash
flutter build appbundle --release
```

Before submitting a release in Play Console, make sure the store listing has a published privacy policy, the Android App Bundle is signed with the Play upload key, and the version in `pubspec.yaml` has been increased.

## Run Locally

```bash
flutter pub get
flutter run
```

To launch a specific target such as macOS:

```bash
flutter run -d macos
```

## Build For macOS

macOS support is already configured in this project. To create a release build:

```bash
flutter build macos
```

The generated app bundle will be available at:

```bash
build/macos/Build/Products/Release/Kartler.app
```

If desktop support is not enabled yet:

```bash
flutter config --enable-macos-desktop
```

## GitHub Releases

The repository includes a GitHub Actions workflow at [.github/workflows/release.yml](.github/workflows/release.yml) that can build release artifacts for:

- Android
- Windows
- macOS
- iOS

When you push a version tag such as `v1.1.4`, GitHub Actions will:

1. Build platform artifacts on the appropriate runners.
2. Verify that the release tag matches the version in `pubspec.yaml`.
3. Run `flutter analyze` and `flutter test`.
4. Collect the commits since the previous tag.
5. Use those commit messages as the release text.
6. Create a GitHub Release and attach all generated files.

## Versioning

The app version is defined in [pubspec.yaml](pubspec.yaml) using Flutter's `version: name+code` format, for example:

```yaml
version: 1.0.0+1
```

Use the semantic version part before `+` as the Git release tag, prefixed with `v`. For `version: 1.0.0+1`, the matching release tag is `v1.0.0`. The release workflow fails if the tag and `pubspec.yaml` version do not match.

Before each release:

- Increase the semantic version when the user-visible app version changes.
- Increase the build number after `+` for each Play Store upload.
- Create a release tag that matches the semantic version exactly.

Create and push a new release tag with:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

You can also start the workflow manually from the GitHub Actions tab by providing an existing tag.

The workflow publishes these assets:

- Android APK
- Android App Bundle (`.aab`)
- Windows ZIP
- macOS ZIP
- iOS unsigned app ZIP

Important note for iOS:

- The workflow builds iOS with `--no-codesign`.
- That means the iOS artifact is useful as a CI build output, but not as an App Store-ready package.
- For TestFlight or App Store distribution, you still need Apple signing certificates, provisioning profiles, and an additional signed archive/export step.

## Tests

The app includes widget, layout, and persistence tests for the main user flows across all modes, including the schema migrations from the old storage format.

Run the full test suite with:

```bash
flutter test
```

Covered scenarios include:

- Zähler: incrementing, resetting, undo, adding, renaming, deleting, and reordering counters
- Watten: score updates, winner display, side reset, auto-recording via `Neues Spiel`, and table mode
- Mulatschak: multipliers, winner logic, history, and Muleqack reset behavior
- Hosn Obe: lives, winner detection, and undo
- Players: global player management, duplicate name handling, and lineups
- Game sessions and statistics: recording matches, leaderboards, and per-mode breakdowns
- Settings: mode, theme, rule profile, history and negative-counter toggles
- Persistence: storage schema migrations, save/load roundtrips, and fallback handling for malformed data

## Privacy

Kartler stores scores, names, history, and app settings locally on the device with `shared_preferences`. The app does not include analytics, advertising SDKs, or third-party tracking SDKs.

Optional donations are handled by the store billing system through `in_app_purchase`. External links, such as bug report links, are opened with `url_launcher` in the user's browser or target app. Those external websites or services are governed by their own privacy policies.

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the full privacy policy.

## Release Checklist

- Confirm `compileSdk` and `targetSdk` are set to `36`.
- Update `version:` in [pubspec.yaml](pubspec.yaml).
- Run `flutter pub get`.
- Run `flutter analyze`.
- Run `flutter test`.
- Confirm the Play Store privacy policy URL points to [PRIVACY_POLICY.md](PRIVACY_POLICY.md) or an equivalent published copy.
- Confirm Android release signing secrets are configured for GitHub Actions.
- Create and push a Git tag matching the semantic version, for example `v1.0.0`.
- Verify the GitHub Release contains the expected Android App Bundle.

## Icons And Generated Files

After a fresh clone, generated files can be recreated locally with:

```bash
flutter pub get
dart run flutter_launcher_icons
```

Notes:

- The launcher icons for Android, iOS, Web, Windows, and macOS are generated from `assets/icon/app_icon.png`.
- The same source image used for Android is also used for the macOS app icon.
- Other generated Flutter files such as plugin registrants are recreated automatically during the first build or run.

## Packages Used

- `shared_preferences` for local storage
- `in_app_purchase` for optional store donations
- `url_launcher` for bug report links
- `flutter_launcher_icons` for app icon generation

## Contributing

Issues and pull requests are welcome.
