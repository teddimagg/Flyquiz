# Flyquiz 🏳️

A fast, native iOS flags-of-the-world quiz built in SwiftUI. Tap, buzz, next. No loading screens, no network, no ads.

## What's in it

- **World Tour campaign**: 7 chapters and ~40 stages covering all 197 countries. Earn 1–3 ★ per stage; stars unlock new chapters.
- **Blitz**: 60 seconds against the clock, getting harder as you go.
- **Daily Challenge**: the same 10 flags for everyone, every day.
- **Review**: spaced-repetition drills on the flags you keep missing.
- **Progression**: XP and levels (Tourist → World Master), combos, day streaks, and a **Flagdex** that tracks mastery of every flag.
- **Snappy by design**: emoji flags (no image assets), instant haptic feedback, about 0.4 s between correct answers, and tap-to-skip on mistakes.

## Project layout

```
App/                      SwiftUI app (views, session, haptics, persistence)
Packages/FlyquizCore/     Pure-Swift game logic: countries, campaign, rounds, progression (+ tests)
project.yml               XcodeGen spec (the .xcodeproj is generated, not committed)
scripts/ci/               Build and TestFlight upload scripts used by CI
.github/workflows/ios.yml CI: core tests on Linux, app build on macOS, TestFlight on main
```

## Developing on a Mac

```sh
brew install xcodegen
xcodegen            # generates Flyquiz.xcodeproj
open Flyquiz.xcodeproj
```

Core logic tests run anywhere Swift does: `swift test --package-path Packages/FlyquizCore`.

## Getting builds on your iPhone

Every push to `main` builds the app and uploads it to **TestFlight**. Setup takes about 15 minutes and is a one-off: see [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md).
