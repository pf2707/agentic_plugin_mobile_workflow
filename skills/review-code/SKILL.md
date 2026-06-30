---
name: review-code
description: Review a mobile code change (diff, PR, or named files). Detects the stack and reports prioritized findings — correctness, crashes, security, performance, style. Read-only.
allowed-tools: Read, Grep, Glob, Bash, Write
---

Review $ARGUMENTS. This is a **read-only** review — do not modify any source files.

## Step 1 — Choose review scope
There are two modes. **If $ARGUMENTS already names a mode (diff/all), specific files, or
a PR, use that and skip the question.** Otherwise you MUST ask the user which mode they
want before reviewing anything — use the AskUserQuestion tool with options "diff" and
"all". Do not silently assume a default; only fall back to **diff** if the question
cannot be asked (e.g. non-interactive run).
- **diff** — the change set. If files/a PR were named, review those;
  otherwise `git diff` + `git diff --staged`; if empty, the latest commit (`git show`).
- **all** — the full source tree under the platform's source root (`/lib` Flutter,
  `/app/src` Android, `/Sources` or `/Classes` iOS, `/src` RN), excluding `/generated`
  and `*.g.dart`. On large codebases, go module by module and prioritize high-severity
  findings over nits.
State which mode and scope you reviewed.

## Step 2 — Detect the stack
Look for: pubspec.yaml (Flutter), package.json + react-native (RN), *.xcodeproj /
Package.swift + *.swift (Swift/SwiftUI), *.m/*.h (Objective-C), build.gradle + *.kt
(Kotlin), build.gradle + *.java (Java). Apply that platform's pitfalls.
Never review or flag code under /generated or *.g.dart.

## Step 3 — Review in priority order
1. Correctness & logic bugs
2. Crashes / lifecycle / memory (force-unwrap, retain cycles, Context leaks, dispose)
3. Concurrency & threading (main-thread UI, races, async misuse)
4. Security (secrets, insecure storage, network/TLS, injection, sensitive logging)
5. Performance (main-thread work, allocations, re-render/rebuild churn)
6. Accessibility & UX
7. Style / conventions (lowest — mark as nits)

## Platform pitfalls
- Swift/SwiftUI: force-unwrap, missing [weak self], UI off @MainActor, heavy body.
- Objective-C: retain cycles, nil-messaging assumptions, un-removed observers.
- Kotlin: Context/Activity leaks, !!, coroutine scope misuse, blocking main.
- Java: inner-class leaks, unclosed resources, main-thread I/O.
- Flutter: setState misuse, missing dispose(), rebuild cost, BuildContext across await.
- React Native: hook deps, re-render churn, inline funcs in lists, key usage.

## Step 4 — Report
Group findings by severity (**Blocker / Major / Minor / Nit**) with `file:line`
references. For each: what is wrong, why it matters, and a suggested fix as a snippet
(do NOT apply it). End with a summary and an overall recommendation
(approve / approve-with-comments / request-changes).

Write the full review to `reports/code-reviewer.md` (create `reports/` if missing) —
the only file you may write — and surface the summary + recommendation in your reply.
