---
name: release-app
description: Cut and ship a mobile release to a beta/internal track. Runs pre-flight gates, detects release tooling, bumps version, builds, distributes, tags, and writes release notes. Manual-trigger only.
disable-model-invocation: true
context: fork
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

Release the app for $ARGUMENTS (default: a beta/internal build of the current branch).
**Manual-trigger only** — this runs only when the user invokes it explicitly.

Publishing is irreversible: distribute to a **beta/internal** track by default and
NEVER promote to a production store track without explicit user confirmation.

## Step 1 — Pre-flight gates (abort on any failure)
- Clean working tree (`git status --porcelain` empty).
- On the intended release branch (confirm if ambiguous).
- Test suite green — run it (or delegate to the Test Agent). Red aborts.
- Confirm target track (beta/internal vs production) and the version to ship.

## Step 2 — Detect platform & tooling
Fastfile → fastlane; eas.json → EAS; else native (xcodebuild + notarytool / 
`./gradlew bundleRelease` / `flutter build ipa|appbundle`). State the tool first.

## Step 3 — Version & build number
Bump marketing version + build/version code in the right file (Info.plist /
project.pbxproj, build.gradle, pubspec.yaml, app.json). Show the diff. Never touch
/generated or *.g.dart.

## Step 4 — Build
Produce the .ipa / .aab. Surface build failures verbatim; do not proceed on failure.

## Step 5 — Distribute
Upload to the agreed track (TestFlight / Play internal by default). Re-confirm before
any production promotion.

## Step 6 — Tag & notes
Create a git tag (e.g. v1.4.0+220) and generate release notes from commits since the
last tag.

## Step 7 — Report
Write the result to `reports/release-app.md` (create `reports/` if missing): platform,
tool, version/build, track, artifact path, gate results, tag, and release notes.
Surface a short summary and any aborted step in your reply.
