# Kartler – OpenCode / AI Agent Instructions

These instructions are mandatory for every AI coding agent working in this repository.

## 1. ABSOLUTE PRE-CHANGE RULE

DO NOT edit, create, delete, rename, format, refactor, generate, or overwrite any project file before completing the read-only inspection below.

Before ANY change:

1. Read `README.md`.
2. Read `pubspec.yaml`.
3. Inspect the relevant files under `lib/`.
4. Inspect existing tests under `test/`, especially layout/widget tests and `test/landscape_layout_test.dart`.
5. Search the codebase for existing implementations/patterns before introducing a new one.
6. Run the current baseline:
   - `flutter analyze`
   - `flutter test`
7. Record any pre-existing failures. Do not silently fix unrelated failures.
8. Produce a short pre-change report containing:
   - what you found,
   - the root cause / intended change,
   - files expected to change,
   - tests that will be added or changed,
   - safe-area / orientation risks.

Only after the inspection and report are complete may you modify files.

Never use "quick fixes" that bypass the existing architecture.

## 2. PROJECT CONTEXT

Kartler is a Flutter/Dart score-counter application.

Main phone modes include:

- Zähler / Counter
- Watten
- Mulatschak
- Hosn Obe

Important UI areas include:

- start screen
- main game/counter screens
- Watten table mode
- drawer
- settings
- player management
- sessions/history/statistics
- dialogs and text-input flows

Preserve all existing behavior unless the requested task explicitly changes it.

## 3. PHONE-SIZE TESTING IS REQUIRED

Any UI/layout change must be validated against the full phone viewport matrix below.

Use logical Flutter pixels for widget tests. A simple approach is:

- `tester.view.devicePixelRatio = 1`
- set `tester.view.physicalSize`
- reset all modified test-view properties in `addTearDown`

Required portrait viewport matrix:

- 320 x 568
- 360 x 640
- 360 x 740
- 375 x 667
- 375 x 812
- 390 x 844
- 393 x 852
- 412 x 732
- 412 x 915
- 414 x 896
- 430 x 932
- 480 x 960

Every viewport above MUST also be tested in landscape by swapping width and height.

Do not test only one "typical" device.

Prefer a parameterized test helper such as:

- `test/helpers/device_matrix.dart`
- `test/responsive_safe_area_test.dart`

instead of duplicating large amounts of test code.

## 4. CAMERA CUTOUT / NOTCH / DYNAMIC ISLAND SAFE AREA

The application UI MUST NOT render functional app content underneath:

- camera cutouts,
- display notches,
- Dynamic Island / sensor housings,
- status-bar unsafe regions,
- gesture/navigation unsafe regions.

This applies to BOTH portrait and landscape.

The usable content rectangle is the safe region after applying the current system insets.

No text, button, card, score, drawer item, dialog action, input field, important icon, or touch target may cross into the unsafe region.

Decorative system/background coloring may extend behind system UI only if it contains no app information or interactive content.

Do NOT hard-code padding for one specific phone model in production code. Use Flutter's system-reported safe-area information (`SafeArea`, `MediaQuery.padding`, `MediaQuery.viewPadding`, or an equivalent architecture-appropriate solution).

## 5. REQUIRED SAFE-AREA TEST PROFILES

For widget/layout tests, emulate cutouts with `tester.view.viewPadding`.

At minimum test all relevant layouts with these profiles.

### Portrait

1. No cutout
   - top: 0
   - right: 0
   - bottom: 0
   - left: 0

2. Standard notch + gesture area
   - top: 44
   - bottom: 34

3. Tall camera/sensor area
   - top: 59
   - bottom: 34

4. Android punch-hole + gesture area
   - top: 32
   - bottom: 24

### Landscape

Test BOTH rotations because the camera area can move to either side.

1. No cutout
   - left: 0
   - right: 0
   - bottom: 0

2. Cutout on left
   - left: 59
   - right: 0
   - bottom: 21

3. Cutout on right
   - left: 0
   - right: 59
   - bottom: 21

4. Symmetric worst-case safe area
   - left: 44
   - right: 44
   - bottom: 21

Always reset:
- physical size,
- device pixel ratio,
- view padding,
- view insets,
- any other modified `TestFlutterView` state.

## 6. SAFE-AREA ASSERTIONS

For each tested screen/state:

- `tester.takeException()` must be `null`.
- There must be no `RenderFlex` overflow or other layout overflow.
- Primary controls must remain visible and usable.
- Important UI rectangles must remain completely inside the safe content rectangle.
- Nothing important may be clipped by the camera/notch side in landscape.
- Nothing important may appear above the safe top edge in portrait.
- Bottom actions must remain above the gesture/navigation safe area.
- Dialogs, drawers, sheets, and text fields must obey the same safe-area rules.
- Keyboard tests must still pass when `viewInsets.bottom` is non-zero.

Do not solve failures by merely hiding, clipping, shrinking, or removing content unless that is explicitly the intended UX.

## 7. REQUIRED SCREEN COVERAGE

The responsive/safe-area smoke matrix must cover at least:

- Zähler main screen
- Watten normal layout
- Watten table mode
- Mulatschak
- Hosn Obe
- navigation drawer
- settings
- player-management UI
- sessions/history/statistics
- important dialogs
- text-input / keyboard state

Existing behavior-focused tests should remain focused. Add a separate parameterized layout/safe-area matrix rather than turning every existing feature test into a huge device matrix.

## 8. IMPLEMENTATION RULES

When fixing responsive layout issues:

- prefer flexible constraints over magic numbers,
- prefer `Expanded`, `Flexible`, `LayoutBuilder`, appropriate scrolling, and safe-area-aware layout where suitable,
- preserve readable text and usable tap targets,
- preserve portrait and landscape behavior,
- preserve Watten table-mode behavior,
- avoid device-name checks,
- avoid platform-specific layout hacks unless required by a platform API,
- keep production code simpler than the test matrix.

If a global safe-area wrapper is appropriate, place it at the correct architectural level so drawers, pages, dialogs, and mode-specific content are not accidentally double-padded.

Check for nested `SafeArea` / `MediaQuery` interactions before adding new padding.

## 9. VALIDATION AFTER CHANGES

After changing code:

1. Run focused tests for the modified area.
2. Run the complete phone-size + safe-area matrix.
3. Run:
   - `flutter analyze`
   - `flutter test`
4. Review the final diff for unrelated changes.
5. Report:
   - files changed,
   - tests added/changed,
   - exact commands run,
   - results,
   - any remaining limitations.

A task involving UI/layout is NOT complete while any required phone viewport, orientation, or safe-area profile fails.

## 10. GIT SAFETY

Do not commit, push, merge, tag, publish a release, or alter GitHub settings unless the user explicitly asks for it.

Do not discard unrelated local changes.

## 11. PRIORITY

If a requested implementation conflicts with these rules, stop before editing and explain the conflict.

The highest UI requirement for this project is:

**The app must remain fully usable on phone sizes from compact to large, in portrait and landscape, and functional content must never render underneath a camera cutout/notch/sensor housing or system unsafe area.**
