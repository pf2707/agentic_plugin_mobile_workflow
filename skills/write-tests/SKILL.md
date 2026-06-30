---
name: write-tests
description: Generate a test suite for the selected file or recent changes. Detects the mobile stack and uses the correct framework, mocking style, and conventions.
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob, Write
---

Generate tests for $ARGUMENTS (default: the most recently changed source file).

## Step 1 — Detect the stack
Look for: *.xcodeproj/Package.swift (Swift), *.m/*.h (ObjC), build.gradle + *.kt (Kotlin),
build.gradle + *.java (Java), pubspec.yaml (Flutter), package.json + react-native (RN).

## Step 2 — Load the matching convention
Read the matching file under references/ (e.g. references/flutter.md) for the exact
framework, imports, naming, and mocking pattern. Do NOT mix frameworks.

## Step 3 — Analyze the target
Identify: public API surface, branches, error paths, async boundaries, and external
dependencies that must be mocked.

## Step 4 — Write tests covering
- Happy path for each public function
- Each conditional branch
- Error/throwing paths
- Edge cases (null/empty/boundary)
- Async success AND failure

## Step 5 — Verify
Place tests in the conventional location, run the suite, and fix until green.

## Step 6 — Report
Write a coverage summary to `reports/write-test.md` (create `reports/` if missing):
platform detected, tests added, suite command + pass/fail result, and what was and
wasn't covered, and why. Surface the summary in your reply too.