---
name: triage-crash
description: Triage a mobile crash or stack trace (Crashlytics, Sentry, Xcode .crash, Android logcat/ANR, Flutter or React Native stack). Detects the platform, finds root cause and offending file:line, assesses severity, and recommends a fix. Diagnoses only unless asked to fix.
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob, Bash, Write, mcp__sentry
---

Triage the crash in $ARGUMENTS (a pasted stack trace, a file path, or a linked
report). **Diagnose only** — do not modify source unless the user explicitly asks.

## Step 1 — Intake (pick the source)
- If the Sentry MCP is connected AND the user pointed at a Sentry issue (ID, URL, or
  "latest crash"), pull it via Sentry — you get a symbolicated stack, frequency, and
  affected releases for free.
- Otherwise use the pasted trace or file path directly (no Sentry needed).
- If the user wants Sentry but it isn't connected, say so, suggest `/mcp` to
  authenticate `sentry`, and offer to proceed now with a pasted trace. Don't block.

Then identify the exception/signal type, message, crashing thread, and whether it is a
hard crash, native signal (SIGSEGV/SIGABRT), or ANR/watchdog timeout.

## Step 2 — Detect the stack
- Swift/Objective-C: Xcode `.crash` / Crashlytics / Sentry — symbolicate with dSYM.
- Kotlin/Java: logcat / ANR trace — deobfuscate with ProGuard/R8 mapping.
- Flutter: Dart stack — resolve with --split-debug-info symbols if obfuscated.
- React Native: Hermes/JSC stack / redbox — resolve with source maps.
If unsymbolicated, say which artifact is needed and proceed with the raw frames.

## Step 3 — Locate & analyze
Find the first in-app frame, read the referenced source, and determine the root cause
(nil/null/force-unwrap, out-of-bounds, illegal state, UI off main thread, bad cast,
OOM, deadlock/ANR, native interop). Separate the crash site from the crash cause.

## Step 4 — Assess
Severity (Critical / High / Medium / Low) and scope (affected OS/device/app versions,
frequency, reproduction conditions).

## Step 5 — Recommend
Give a concrete minimal fix as a snippet with the target file:line, plus a guardrail
or a regression test to add. Apply it to source only if the user asked.

## Step 6 — Report
Write the triage to `reports/crash_triage.md` (create `reports/` if missing):
exception type & message, platform, symbolication status, root cause, offending
file:line, severity, scope, and recommended fix. Surface a short summary in your reply.
