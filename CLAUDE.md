# MOBILE AGENT KIT
This is a plugin encapsulating various agents that support mobile app in production and release stage.

## Overview
- Platform: iOS / iPadOS / Android / Flutter / React Native
- Programming Lanugage: Objective C, Swift, SwiftUI, Java, Kotlin, Dart, Javascript, TypeScript
- Source: /lib (Flutter) or /app/src (Android) or /Sources (iOS, iPadOS) or /Classes (iOS / iPadOS) or /src (React Native). If no folder as specific, decide as yourself
- Never edit anything under /generated or *.g.dart
- All documents should be places under folder `docs/`. Before implementing any thing, please update document `plan.md` and breakdown step by step
- All the results come from all agents should be created to folder `reports` such as `reports/write-test.md`, `reports/code-reviewer.md`, `reports/crash_triage.md`, `reports/release-app.md`

## Agent 1: Test Agent
- Test framework: Swift Testing / JUnit5+Espresso / flutter_test / Jest+RTL
- Run the test suite before declaring any task done
- Generate test reference for each platform under folder `write-tests/references/`
- Agent should detect platform before running suitable reference file for this platform.

## Agent 2: Code Review Agent
- Read-only review; never edits source. User selects the scope: **diff** mode (current `git diff` / staged / a PR / named files — the default) or **all** mode (the full source tree under the platform's source root, excluding `/generated` and `*.g.dart`).
- Detect platform before reviewing, then apply that platform's pitfall checklist.
- Review in priority order: correctness > crashes/lifecycle/memory > concurrency > security > performance > accessibility > style.
- Report findings by severity (Blocker / Major / Minor / Nit) with `file:line`, the why, and a suggested fix snippet. End with an overall recommendation.
- Write the result to `reports/code-reviewer.md`.

## Agent 3: Crash Triage Agent
- Input: a crash report or stack trace (Crashlytics / Sentry / Xcode `.crash` / Android logcat & ANR / Flutter stack / React Native Hermes stack).
- Detect platform, parse the exception type and frames, and note any symbolication/deobfuscation needed (iOS dSYM, Android ProGuard/R8 mapping, RN source maps).
- Identify the root cause, locate the offending `file:line`, and assess severity and affected scope.
- Recommend a concrete fix (diagnose first; only apply a fix if asked).
- Write the result to `reports/crash_triage.md`.

## Agent 4: Release Automation Agent
- **Manual-trigger only.** Its skill sets `disable-model-invocation: true`; the model never auto-runs a release — the user invokes it explicitly.
- Run pre-flight gates first: clean git tree, correct release branch, and a green test suite (delegate to the Test Agent if needed). Abort if any gate fails.
- Detect platform and release tooling: fastlane (`Fastfile`) / EAS (`eas.json`) / Gradle / xcodebuild / `flutter build`.
- Bump version + build number, build the artifact (ipa / aab), and distribute to a **beta/internal track by default** (TestFlight / Play internal).
- **Publishing is irreversible** — never promote to a production store track without explicit user confirmation. Default to a dry run when unsure.
- Tag the release and generate release notes.
- Write the result to `reports/release-app.md`.


