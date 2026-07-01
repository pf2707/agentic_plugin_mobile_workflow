# Mobile Agent Kit

A [Claude Code](https://claude.com/claude-code) plugin that packages four production-grade
AI subagents for the **mobile app lifecycle** — test generation, code review, crash triage,
and release automation — across iOS, Android, Flutter, and React Native.

Each agent **detects the stack first**, then applies platform-correct tooling, idioms, and
safety rails. The kit is designed around a single principle: *agents should be useful by
default and safe by construction.*

---

## What's inside

| Agent | What it does | Trigger | Writes to |
|-------|--------------|---------|-----------|
| 🧪 **Test Writer** | Detects the stack, generates an idiomatic test suite with the right framework + mocking style, then **runs it and fixes failures** before reporting done. | `/write-tests` | `reports/write-test.md` |
| 🔍 **Code Reviewer** | **Read-only** review of a diff / PR / files. Severity-ordered findings (Blocker → Nit) with `file:line`, the *why*, and a suggested fix. Never edits source. | `/review-code` | `reports/code-reviewer.md` |
| 💥 **Crash Triage** | Parses a crash/stack trace (Crashlytics, Sentry, Xcode `.crash`, logcat/ANR, Hermes), finds root cause + offending `file:line`, assesses severity. Diagnoses only unless asked to fix. | `/triage-crash` | `reports/crash_triage.md` |
| 🚀 **Release Automation** | **Manual-trigger only.** Pre-flight gates (clean tree, branch, green tests) → version bump → build → distribute to a **beta/internal track by default**. | `/release-app` | `reports/release-app.md` |

**Supported stacks:** Swift/SwiftUI, Objective-C, Kotlin, Java, Flutter (Dart), React Native (TS/JS).

---

## Install

This repo is a Claude Code **plugin marketplace**. From inside Claude Code:

```
/plugin marketplace add pf2707/agentic_plugin_mobile_workflow
```

Then the slash commands (`/write-tests`, `/review-code`, `/triage-crash`, `/release-app`)
and their subagents become available in any mobile repo.

> **Heads up — bundled MCP server.** Crash Triage can pull symbolicated stacks and
> frequency data from [Sentry's hosted MCP](https://mcp.sentry.dev/mcp). On install Claude
> Code will ask you to trust this remote server. It's **optional** — the agent degrades
> gracefully to a pasted/exported trace if Sentry isn't connected. It ships disabled in
> `.claude/settings.local.json` and you can leave it off.

---

## How it works

```
agentic_plugin_mobile_workflow/
├── .claude-plugin/
│   ├── plugin.json          # plugin manifest (name, version, author)
│   └── marketplace.json     # marketplace manifest → makes this repo installable
├── agents/                  # the 4 subagent definitions (frontmatter + system prompt)
├── skills/                  # slash-command entry workflows
│   └── write-tests/references/   # per-platform test cookbooks (loaded on demand)
├── .mcp.json                # Sentry MCP wiring for the crash agent
├── docs/plan.md             # design doc: goals, framework matrix, definition-of-done per agent
└── CLAUDE.md                # project rules every agent inherits
```

### Design decisions worth calling out

- **Platform detection before action.** No agent assumes a stack. They probe for
  `pubspec.yaml`, `Package.swift`, `build.gradle`, `package.json + react-native`, etc., then
  branch. One plugin, five ecosystems.
- **Progressive disclosure via references.** The Test Writer doesn't carry six frameworks in
  one bloated prompt — it loads only the matching `references/*.md` cookbook (Swift Testing,
  JUnit5+Espresso, flutter_test, Jest+RTL…) after detecting the platform. Smaller context,
  sharper output.
- **Least privilege per agent.** The Code Reviewer is granted read-only tools and *cannot*
  edit source. The Release agent gets `Edit` only for version bumps. Capability is scoped to
  intent.
- **Safety by construction for irreversible actions.** Releases are `disable-model-invocation:
  true` (the model never auto-ships), gated on a clean tree + green tests, and default to a
  **beta/internal** track — production promotion requires explicit human confirmation.
- **Graceful degradation.** Crash triage prefers Sentry when connected but never *requires*
  it; a pasted trace works just as well.
- **Auditable output.** Every run writes a structured report under `reports/` and surfaces a
  summary inline, so results are reviewable, not ephemeral.
- **Enforced, not just requested.** A prompt instruction to "write a report" is one the model
  can silently skip. A `SubagentStop` hook (`hooks/ensure-test-report.sh`) blocks the Test
  Agent from finishing until `reports/write-test.md` actually exists — turning a hoped-for
  step into a guaranteed one. Fails open if `jq` is missing so it never breaks a run.

See [`docs/plan.md`](docs/plan.md) for the full design doc — per-agent goals, the framework
matrix, and the definition-of-done that gates each agent.

---

## License

[MIT](LICENSE) © Thai Tran
