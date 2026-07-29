#!/usr/bin/env bash
# tools/devtools-check.sh
# Meta-check: validates the AI development tools themselves
# are consistent with the current repo state.
#
# When this fails, AI knows which dev tool needs updating.
# Part of the devtools self-improvement mechanism.

set -euo pipefail
export NO_COLOR=1

# Resolve repo root
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

PASS=0
FAIL=0
ERRORS=""

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); ERRORS="${ERRORS}  $1"$'\n'; }

echo "=== devtools-check ===" >&2

# ── A: repo-index freshness ──
echo "[A] repo-index freshness" >&2

if bash checks/check-repo-index.sh >/dev/null 2>&1; then
  echo "  PASS: repository index is current" >&2
  pass
else
  echo "  FAIL: repository index is stale" >&2
  fail "repo-index: generated index differs"
fi

# ── B: query coverage ──
echo "[B] query coverage" >&2

tmp_summary="$(mktemp)"
trap 'rm -f "$tmp_summary"' EXIT

proof_base=fixtures/ledger-facts-phase1-proof
compact_manifest="$proof_base/report_all_compact.destination.tsv"
if ./tools/report-summary "$proof_base" "$compact_manifest" >"$tmp_summary" 2>/dev/null; then
  total_keys=$(grep -c '^ledger_' "$tmp_summary" || echo 0)
  echo "  INFO: destination summary exposes $total_keys ledger_* rows" >&2
  first_key=$(sed -n '/^ledger_/{s/: .*//;p;q;}' "$tmp_summary")
  if [[ -n $first_key ]] && ./tools/query-destination "$proof_base" "$compact_manifest" "$first_key" >/dev/null 2>&1; then
    echo "  PASS: exact query can retrieve a key (sample: $first_key)" >&2
    pass
  else
    echo "  FAIL: exact destination query failed for key: $first_key" >&2
    fail "query: cannot retrieve key $first_key"
  fi
  if ./tools/query-destination "$proof_base" "$compact_manifest" --list >/dev/null 2>&1; then
    echo "  PASS: exact query --list works" >&2
    pass
  else
    echo "  FAIL: exact query --list failed" >&2
    fail "query: --list failed"
  fi
  if ./tools/query-destination "$proof_base" "$compact_manifest" --keys >/dev/null 2>&1; then
    echo "  PASS: exact query --keys works" >&2
    pass
  else
    echo "  FAIL: exact query --keys failed" >&2
    fail "query: --keys failed"
  fi
else
  echo "  FAIL: destination report summary failed on public proof fixture" >&2
  fail "summary: destination compact route failed"
fi

# ── C: bqn-eval liveness ──
echo "[C] bqn-eval liveness" >&2
if result=$(bash ./tools/bqn-eval '•Out "ok"' 2>&1) && [ "$result" = "ok" ]; then
  echo "  PASS: bqn-eval works (•Out ok)" >&2
  pass
else
  echo "  FAIL: bqn-eval liveness check failed (got: $result)" >&2
  fail "bqn-eval: liveness check failed"
fi

# ── D: bqn-dump liveness ──
echo "[D] bqn-dump liveness" >&2
if result=$(bash ./tools/bqn-dump '1' 2>&1) && echo "$result" | grep -q 'kind: number'; then
  echo "  PASS: bqn-dump works" >&2
  pass
else
  echo "  FAIL: bqn-dump liveness check failed" >&2
  fail "bqn-dump: liveness check failed"
fi

# ── E: rtk / sqz availability ──
echo "[E] rtk / sqz availability" >&2
if command -v rtk >/dev/null 2>&1; then
  echo "  PASS: rtk available ($(command -v rtk))" >&2
  pass
else
  echo "  WARN: rtk not found (non-fatal)" >&2
  # rtk is optional, don't fail
fi

if command -v sqz >/dev/null 2>&1; then
  echo "  PASS: sqz available ($(command -v sqz))" >&2
  pass
else
  echo "  WARN: sqz not found (non-fatal)" >&2
  # sqz is optional, don't fail
fi

# ── F: stale tool references ──
echo "[F] stale tool references in docs" >&2

# Tools known to be removed from the current tree
STALE_TOOLS=("tools/sqz-report" "lint_cli.bqn")
STALE_FOUND=0

for tool in "${STALE_TOOLS[@]}"; do
  # Search non-archive, non-status docs for the stale tool name
  # Exclude files that intentionally document historical context:
  # - DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md (historical record)
  # - BQN_REPL_AND_DUMPER_DESIGN.md (comparison reference)
  # - DRIFT_FIX_PLAN-*.md (already fixing)
  # - AI_AGENT_EFFICIENCY_PLAN.md (historical reference)
  refs=$(grep -rn "$tool" docs/ AGENTS.md 2>/dev/null \
    | grep -v 'docs/archive/' \
    | grep -v '削除済み' \
    | grep -v 'DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md' \
    | grep -v 'BQN_REPL_AND_DUMPER_DESIGN.md' \
    | grep -v 'DRIFT_FIX_PLAN' \
    | grep -v 'DRIFT_AUDIT' \
    | grep -v 'AI_AGENT_EFFICIENCY_PLAN.md' \
    | grep -v 'OUTPUT_SQUEEZER_DESIGN.md' \
    | grep -v 'OLD_ENGINE_REMOVAL_PLAN.md' \
    | grep -v 'REPO_INDEX_DESIGN.md' \
    | grep -v 'REPO_INDEX_IMPLEMENTATION_HANDOFF.md' \
    | grep -v 'SAFETY_PROFILE_INVARIANT_MAP.md' \
    | grep -v 'PHASE4_BASE_AWARE_CONTEXT_INVESTIGATION.md' \
    | grep -v '^docs/README.md:' \
    || true)
  
  if [ -n "$refs" ]; then
    STALE_FOUND=$((STALE_FOUND + 1))
    echo "  STALE: $tool referenced in:" >&2
    echo "$refs" | while read -r line; do
      echo "    $line" >&2
    done
    fail "stale-ref: $tool still referenced in active docs"
  fi
done

if [ "$STALE_FOUND" -eq 0 ]; then
  echo "  PASS: no stale tool references in active docs" >&2
  pass
fi

# ── G: scaffold-check existence (informational) ──
echo "[G] scaffold-check" >&2
if [ -x "./tools/scaffold-check.sh" ]; then
  echo "  PASS: scaffold-check.sh exists" >&2
  pass
else
  echo "  INFO: scaffold-check.sh not yet implemented (Phase B)" >&2
fi

# ── H: CLI tools liveness (with colors enabled) ──
echo "[H] CLI tools liveness (with colors enabled)" >&2
# Temporarily unset NO_COLOR to test color theme loading in non-plain environments
if env -u NO_COLOR ./tools/bl help >/dev/null 2>&1; then
  echo "  PASS: tools/bl launches successfully with colors enabled" >&2
  pass
else
  echo "  FAIL: tools/bl fails to launch with colors enabled" >&2
  fail "liveness: tools/bl launch failed with colors"
fi

if env -u NO_COLOR ./tools/main-ui.sh --help >/dev/null 2>&1; then
  echo "  PASS: tools/main-ui.sh launches successfully with colors enabled" >&2
  pass
else
  echo "  FAIL: tools/main-ui.sh fails to launch with colors enabled" >&2
  fail "liveness: tools/main-ui.sh launch failed with colors"
fi

if env -u NO_COLOR ./tools/add-ui.sh --help >/dev/null 2>&1; then
  echo "  PASS: tools/add-ui.sh launches successfully with colors enabled" >&2
  pass
else
  echo "  FAIL: tools/add-ui.sh fails to launch with colors enabled" >&2
  fail "liveness: tools/add-ui.sh launch failed with colors"
fi

# ── Summary ──

echo "" >&2
echo "devtools-check: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  echo "FAILURES:" >&2
  echo "$ERRORS" >&2
  exit 1
fi
echo "OK" >&2
