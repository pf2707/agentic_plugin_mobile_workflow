#!/usr/bin/env bash
# SubagentStop hook — Mobile Agent Kit
#
# Guarantees the Test Agent writes its coverage report (reports/write-test.md)
# before the subagent is allowed to finish. Without this, "write the report" is
# only a prompt instruction the model can silently skip — which is exactly how a
# run can end with test files on disk but no report of pass/fail.
#
# Contract (see https://code.claude.com/docs/en/hooks):
#   - stdin  : JSON with .agent_type, .cwd, .transcript_path, .stop_hook_active
#   - exit 2 : blocks the subagent from stopping; stderr is fed back to the agent
#   - exit 0 : allow the subagent to stop
#
# DEBUG: every invocation appends one line to
#   "${TMPDIR:-/tmp}/mobile-agent-kit-hook.log"
# showing what the hook received and what it decided. Inspect it with:
#   cat "${TMPDIR:-/tmp}/mobile-agent-kit-hook.log"
# (This log is temporary diagnostic aid; safe to delete.)
set -uo pipefail

log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" >>"${TMPDIR:-/tmp}/mobile-agent-kit-hook.log"; }

input=$(cat)

# Fail OPEN if jq is unavailable — never break a user's run over our own tooling.
if ! command -v jq >/dev/null 2>&1; then
  log "DECIDE=skip reason=jq-missing"
  echo "ensure-test-report: jq not found; skipping report enforcement." >&2
  exit 0
fi

agent_type=$(printf '%s' "$input" | jq -r '.agent_type // ""')
cwd=$(printf '%s' "$input" | jq -r '.cwd // "."')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""')
stop_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')

log "SEEN agent_type='${agent_type}' cwd='${cwd}' transcript='${transcript}' stop_active='${stop_active}'"

# Loop guard: if we already blocked once this turn, let the subagent stop.
if [ "$stop_active" = "true" ]; then
  log "DECIDE=allow reason=loop-guard"
  exit 0
fi

# Is this a test-writing run? Match on any of several signals so we catch both the
# /write-tests skill fork and the standalone test-writer agent, regardless of how
# agent_type is reported:
#   1) agent_type mentions the test-writer agent, or
#   2) the transcript shows the test workflow ran — it loaded a reference cookbook
#      ("write-tests/references") or references the report path itself
#      ("reports/write-test.md"), both of which appear in the skill/agent prompt.
is_test_run=false
matched=""
case "$agent_type" in *test-writer*) is_test_run=true; matched="agent_type" ;; esac
if [ "$is_test_run" = false ] && [ -n "$transcript" ] && [ -f "$transcript" ]; then
  if grep -qE "write-tests/references|reports/write-test\.md|write-tests" "$transcript"; then
    is_test_run=true; matched="transcript"
  fi
fi

if [ "$is_test_run" != true ]; then
  log "DECIDE=allow reason=not-a-test-run (no signal matched)"
  exit 0
fi

report="$cwd/reports/write-test.md"
if [ ! -f "$report" ]; then
  log "DECIDE=BLOCK reason=report-missing matched=${matched} expected='${report}'"
  cat >&2 <<'MSG'
BLOCKED: the Test Agent has not written its required coverage report.
Before finishing, create `reports/write-test.md` (make the `reports/` folder if
needed) containing:
  - the platform detected,
  - the test files added (paths),
  - the exact suite command run and its pass/fail result,
  - what was covered, what was not, and why.
MSG
  exit 2
fi

log "DECIDE=allow reason=report-exists matched=${matched} path='${report}'"
exit 0
