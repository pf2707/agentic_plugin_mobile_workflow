# Plan

## Agent 1: Test Agent — implementation

Goal: a subagent that generates and runs a platform-correct test suite for a mobile
app, detecting the stack before choosing a framework, and never declaring done until
the suite is green.

### Scope of this iteration (Agent 1 only)
Agents 2–4 (Code Review, Release Automation, Crash Triage) are out of scope here.

### Steps
1. [x] Write `agents/test-writer.md` — the Test Agent definition.
   - Frontmatter: name, description, tools, model.
   - Detect platform → load the matching `skills/write-tests/references/*.md`.
   - Run the test suite before reporting done.
2. [x] Fill the empty platform reference files under `skills/write-tests/references/`:
   - `swift-swiftui.md` — Swift Testing (`@Test`, `#expect`).
   - `objective-c.md` — XCTest + OCMock.
   - `kotlin.md` — JUnit5 + Espresso + MockK.
   - `java.md` — JUnit5 + Mockito.
   - `react-native.md` — Jest + React Testing Library.
   - `flutter.md` — already done (flutter_test + mocktail).
3. [x] Keep the existing `skills/write-tests/SKILL.md` as the entry workflow.

### Framework matrix (per CLAUDE.md)
| Platform        | Framework             | Mocking   |
|-----------------|-----------------------|-----------|
| iOS Swift/SwiftUI | Swift Testing       | protocol stubs |
| iOS Objective-C | XCTest                | OCMock    |
| Android Kotlin  | JUnit5 + Espresso     | MockK     |
| Android Java    | JUnit5                | Mockito   |
| Flutter         | flutter_test          | mocktail  |
| React Native    | Jest + RTL            | jest.mock |

### Definition of done
- Tests placed in the conventional location for the stack.
- Suite runs and passes (or failures are reported with the output).
- Coverage summary reported: what is and isn't covered, and why.

## Agent 2: Code Review Agent — implementation

Goal: a read-only subagent that reviews mobile code changes (a diff, a PR, or named
files), detects the stack, and reports prioritized findings — correctness, then
platform-specific pitfalls, security, performance, and style — without editing code.

### Scope of this iteration (Agent 2 only)
No spec was given in CLAUDE.md, so the design follows Agent 1's conventions:
platform detection first, mobile-aware checks, documents under `docs/`.

### Steps
1. [x] Write `agents/code-reviewer.md` — the Code Review Agent definition.
   - Frontmatter: name, description, tools (read-only: Read/Grep/Glob/Bash), model.
   - Detect platform → apply the matching review checklist.
   - Scope selectable by the user: `diff` (current diff / staged / PR / named files —
     default) or `all` (full source tree under the platform source root, excluding
     `/generated` and `*.g.dart`).
   - Read-only: never edits source; emits a review report.
2. [x] Fill `skills/review-code/SKILL.md` — the entry workflow.

### Review priority (highest first)
1. Correctness & logic bugs
2. Crashes / lifecycle / memory (retain cycles, context leaks, null/force-unwrap)
3. Concurrency & threading (main-thread UI, races, unstructured async)
4. Security (secrets, insecure storage, network/TLS, injection)
5. Performance (main-thread work, allocations, unnecessary re-render/rebuild)
6. Accessibility & UX
7. Style / conventions (lowest)

### Platform pitfalls cheat-sheet
| Platform        | Watch for                                              |
|-----------------|--------------------------------------------------------|
| Swift/SwiftUI   | force-unwrap, retain cycles in closures ([weak self]), main-actor UI, excessive body recompute |
| Objective-C     | retain cycles, nil messaging assumptions, manual KVO removal |
| Kotlin          | Context/Activity leaks, nullability (!!), coroutine scope misuse |
| Java            | leaks via inner classes, unclosed resources, threading on main |
| Flutter         | setState misuse, missing dispose(), rebuild cost, BuildContext across async gaps |
| React Native    | missing deps in hooks, re-render churn, inline funcs in lists, key usage |

### Definition of done
- Findings grouped by severity (Blocker / Major / Minor / Nit) with file:line refs.
- Each finding states the problem, why it matters, and a suggested fix.
- No source files modified (report file under `reports/` excepted).

## Reports requirement (all agents)
Per CLAUDE.md, every agent writes its result under `reports/`:
- Test Agent → `reports/write-test.md`
- Code Review Agent → `reports/code-reviewer.md`
- Crash Triage Agent → `reports/crash_triage.md`
- Release Automation Agent → `reports/release-app.md`
Agents create the `reports/` folder if it does not exist and also surface a summary
in their reply.

## Agent 3: Crash Triage Agent — implementation

Goal: ingest a crash report / stack trace, detect the platform, find the root cause
and the offending `file:line`, assess severity and scope, recommend a fix, and write
a triage report.

### Steps
1. [x] Write `agents/crash_triage.md` — the Crash Triage Agent definition.
   - Frontmatter: name, description, tools (Read/Grep/Glob/Bash/Write), model.
   - Parse exception + frames; note symbolication/deobfuscation needs.
   - Diagnose first; only apply a fix if explicitly asked.
   - Write `reports/crash_triage.md`.
2. [x] Add `skills/triage-crash/SKILL.md` — the entry workflow.
3. [x] Wire a data layer (MCP): Sentry hosted MCP in `.mcp.json`; grant `mcp__sentry`
   to the agent and skill. Intake is enrichment-not-mandatory: prefer Sentry when
   connected and an issue is referenced (symbolicated stack + frequency for free),
   otherwise fall back to a pasted/file trace; degrade gracefully if Sentry is absent.
   - Crashlytics: no first-party MCP. Fallback = read an exported crash JSON. A thin
     MCP over the Crashlytics→BigQuery export is a possible future component.

### Crash sources by platform
| Platform        | Crash source / format                         | Symbolication |
|-----------------|-----------------------------------------------|---------------|
| Swift / ObjC    | Xcode `.crash`, Crashlytics, Sentry           | dSYM          |
| Kotlin / Java   | logcat stack, ANR trace, Crashlytics          | ProGuard/R8 mapping |
| Flutter         | Dart stack trace, Crashlytics                 | `--split-debug-info` symbols |
| React Native    | Hermes/JSC stack, redbox, Sentry              | source maps   |

### Definition of done
- Report names exception type, root cause, and offending `file:line`.
- Severity + affected scope assessed; concrete fix recommended.
- Written to `reports/crash_triage.md`; no source changed unless asked.

## Agent 4: Release Automation Agent — implementation

Goal: a **manual-trigger-only** agent that takes a vetted build to a beta/internal
distribution track safely, with hard pre-flight gates and no surprise production
publishes.

### Steps
1. [x] Write `agents/release-app.md` — the Release Automation Agent definition.
   - Tools: Read/Grep/Glob/Bash/Write/Edit (Edit for version bumps).
   - Pre-flight gates → detect tooling → bump → build → distribute (beta default) → tag/notes.
   - Confirm before any irreversible/production step.
2. [x] Fill `skills/release-app/SKILL.md` with `disable-model-invocation: true`
   (manual trigger only — per user request).

### Safety stance
- Publishing is outward-facing and irreversible: beta/internal track by default;
  production promotion requires explicit user confirmation; dry-run when unsure.

### Release tooling by platform
| Platform        | Build + distribute                                  |
|-----------------|-----------------------------------------------------|
| iOS Swift/ObjC  | fastlane (gym + pilot) or xcodebuild + notarytool → TestFlight |
| Android K/J     | fastlane (gradle + supply) or `./gradlew bundleRelease` → Play internal |
| Flutter         | `flutter build ipa/appbundle` then fastlane upload  |
| React Native    | EAS (`eas build` / `eas submit`) or fastlane        |

### Definition of done
- Pre-flight gates pass (clean tree, branch, green tests) or release aborts.
- Artifact built and distributed to the agreed track; release tagged + notes written.
- Written to `reports/release-app.md`; no production publish without confirmation.
