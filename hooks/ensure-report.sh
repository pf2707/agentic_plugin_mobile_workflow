#!/usr/bin/env bash
# SubagentStop hook — Mobile Agent Kit
#
# Ensures each agent writes its required report under reports/ before the
# subagent is allowed to finish. "Write a report" is otherwise a soft prompt
# step the model can silently skip; this turns it into a guarantee for every
# report-producing agent in the kit.
#
# Contract (https://code.claude.com/docs/en/hooks): stdin is JSON with
# .agent_type, .cwd, .transcript_path, .stop_hook_active. exit 2 blocks the
# subagent from stopping and feeds stderr back to it; exit 0 lets it stop.
#
# DEBUG (opt-in): set MOBILE_KIT_HOOK_DEBUG=1 to append one line per invocation
# to "${TMPDIR:-/tmp}/mobile-agent-kit-hook.log". Off by default.
set -uo pipefail

log() {
  [ -n "${MOBILE_KIT_HOOK_DEBUG:-}" ] || return 0
  printf '%s %s\n' "$(date +%H:%M:%S)" "$*" >>"${TMPDIR:-/tmp}/mobile-agent-kit-hook.log"
}

input=$(cat)

# Fail OPEN if jq is unavailable — never break a user's run over our own tooling.
if ! command -v jq >/dev/null 2>&1; then
  log "DECIDE=skip reason=jq-missing"
  echo "ensure-report: jq not found; skipping report enforcement." >&2
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

tdata=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  tdata=$(cat "$transcript")
fi

# Enforce the report for whichever workflow ran. Signal that a workflow ran:
#   - agent_type contains the agent's keyword (standalone agent path), OR
#   - the transcript references the report path (skill-fork path — each skill's
#     prompt names its own report file, so it appears in the fork transcript).
# If the workflow ran but its report file is missing, block and ask for it.
check() {
  local rpath="$1" kw="$2" label="$3"
  local ran=false
  case "$agent_type" in *"$kw"*) ran=true ;; esac
  if [ "$ran" = false ] && [ -n "$tdata" ] && printf '%s' "$tdata" | grep -q "$rpath"; then
    ran=true
  fi
  [ "$ran" = true ] || return 0

  if [ ! -f "$cwd/$rpath" ]; then
    log "DECIDE=BLOCK reason=report-missing label='$label' expected='$cwd/$rpath'"
    printf 'BLOCKED: the %s has not written its required report.\n' "$label" >&2
    printf 'Before finishing, create `%s` (make the `reports/` folder if needed),\n' "$rpath" >&2
    printf 'then stop.\n' >&2
    exit 2
  fi
  log "DECIDE=allow reason=report-exists label='$label' path='$cwd/$rpath'"
}

# report path : agent_type keyword : human label
check "reports/write-test.md"    "test-writer"  "Test Agent"
check "reports/crash_triage.md"  "crash"        "Crash Triage Agent"
check "reports/code-reviewer.md" "code-review"  "Code Review Agent"
check "reports/release-app.md"   "release"      "Release Automation Agent"

log "DECIDE=allow reason=no-report-required-or-all-present"
exit 0
