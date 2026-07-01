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
set -uo pipefail

input=$(cat)

# Fail OPEN if jq is unavailable — never break a user's run over our own tooling.
if ! command -v jq >/dev/null 2>&1; then
  echo "ensure-test-report: jq not found; skipping report enforcement." >&2
  exit 0
fi

agent_type=$(printf '%s' "$input" | jq -r '.agent_type // ""')
cwd=$(printf '%s' "$input" | jq -r '.cwd // "."')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""')
stop_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')

# Loop guard: if we already blocked once this turn, let the subagent stop.
[ "$stop_active" = "true" ] && exit 0

# Only enforce on test-writing runs. Two signals:
#   1) the Test Agent subagent (agent_type contains "test-writer"), or
#   2) any subagent that loaded a write-tests reference cookbook (both the
#      /write-tests skill fork and the test-writer agent read one).
is_test_run=false
case "$agent_type" in *test-writer*) is_test_run=true ;; esac
if [ "$is_test_run" = false ] && [ -n "$transcript" ] && [ -f "$transcript" ]; then
  grep -q "write-tests/references" "$transcript" && is_test_run=true
fi
[ "$is_test_run" = true ] || exit 0

report="$cwd/reports/write-test.md"
if [ ! -f "$report" ]; then
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

exit 0
