# 0007. Native app: Expo vs Capacitor

- **Status:** Proposed — to be decided at the start of phase 4, after a spike
- **Date:** 2026-11-26

## Context

The native app goes to the App Store and Google Play. The mobile layout is the product's source of truth, and the design system exists as React DOM + CSS (variable Bricolage Grotesque at 75% width, SVG mascots and icons, spring animations in CSS). Two question kinds (Sequence, Match pairs) rely on tactile interactions where native feel matters.

Until phase 4, the web PWA covers mobile use.

## Options

### Expo (React Native)
- **+** Native gestures, navigation and animations (Reanimated); best "feels like an app" result.
- **+** EAS Build / Update (cloud builds, over-the-air JS updates); lower App Review risk.
- **−** The design system must be reimplemented in React Native primitives (`View`/`Text`, `react-native-svg`, Reanimated). Two UI implementations (web + native) sharing `contracts`, `core` and `tokens`.
- **−** No `font-stretch` in React Native: generate static condensed instances of Bricolage.
- Middle ground: Expo "DOM components" (`'use dom'`) can host React DOM components inside the native app, allowing a gradual port.

### Capacitor (web app in a native shell)
- **+** Reuses `apps/web` and the design system 1:1; one UI codebase for all three surfaces.
- **−** Runs in a WebView: drag interactions and heavy animations may feel worse on low-end Android.
- **−** Native feel (swipe-back, screen transitions, keyboard behaviour) is our job.
- **−** App Store guideline 4.2 risk ("repackaged website"), mitigated with native features (push, haptics, Sign in with Apple, offline).
- **−** Native `ios/` and `android/` projects live in the repo and need occasional Xcode/Gradle work.

Native widgets (e.g. a streak widget) or Live Activities need Swift/Kotlin code in either option.

## Decision process

Spike both, ~1–2 days each: the lab trail screen and a drag-based Match pairs question, run on an iPhone and on a low-end Android. Compare interaction feel, effort to port design-system components, and impact on the web/desktop experience. Record the outcome here and set the status to Accepted.

Prerequisites: Xcode and Android Studio installed (not present on the dev machine as of 2026-11-26), ideally a physical low-end Android device.
