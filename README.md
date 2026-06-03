# Counter

A Flutter app for tracking different counters and scoreboards in one place. In addition to classic counters, the app includes a Watten mode and a Mulatschak mode with locally persisted game state.

This repository contains the source code, assets, and configuration. Generated Flutter artifacts and platform-specific build outputs are recreated locally.

## Features

- Three modes in one app: `Counter`, `Watten`, and `Mulatschak`
- Local persistence for all values via `shared_preferences`
- Undo support for the most recent action
- Drawer-based management for creating, selecting, renaming, deleting, and reordering items
- Settings for app mode, theme, and Mulatschak reset behavior
- Platform folders included for Android, iOS, Web, Windows, Linux, and macOS

## Modes

### Counter

- Manage multiple counters
- Add, rename, delete, and reorder counters
- Track values with `+`, `-`, and `Reset`
- Default counters on first launch: `Workout streak`, `Days without smoking`, and `Days till my next holidays` with a starting value of `100`

### Watten

- Manage multiple games in parallel
- Separate score tracking for `Me` and `You`
- Quick scoring buttons for `+2` and `+3`
- Reset only the currently selected side
- Winner banner when one side has more than `10` points and leads the other side

### Mulatschak

- Manage multiple players
- Select the active player directly from the player cards
- Score controls for `-1`, `+1`, and `+5`
- Multipliers `1x`, `2x`, `4x`, `8x`, `16x`, plus extra values via dropdown
- Optional Muleqack reset with configurable threshold and reset value
- Winner banner when a player reaches `0`

## Usage

1. Open the drawer from the menu in the app bar.
2. Select a counter, game, or player, or create a new one.
3. Adjust the current value using the controls for the active mode.
4. Use `Undo` to revert the most recent action.
5. Open `Settings` to change the mode, theme, and Mulatschak reset settings.

## Requirements

- Flutter SDK
- Dart SDK compatible with the Flutter version used by the project
- Xcode for iOS and macOS builds on macOS

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
build/macos/Build/Products/Release/counter_app.app
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
2. Collect the commits since the previous tag.
3. Use those commit messages as the release text.
4. Create a GitHub Release and attach all generated files.

Create and push a new release tag with:

```bash
git tag -a v1.1.4 -m "Release v1.1.4"
git push origin v1.1.4
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

The app includes widget and persistence tests for the main user flows across all modes.

Run the full test suite with:

```bash
flutter test
```

Covered scenarios include:

- Counter: incrementing, resetting, undo, adding, renaming, and deleting counters
- Watten: updating scores, switching sides, resetting, winner display, and game management
- Mulatschak: multipliers, winner logic, player management, and Muleqack reset behavior
- Persistence: default values, save/load roundtrips, and fallback handling for malformed data

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
- `url_launcher` for the donation link
- `flutter_launcher_icons` for app icon generation

## Contributing

Issues and pull requests are welcome.
