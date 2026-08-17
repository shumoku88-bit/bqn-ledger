#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-operations.XXXXXX")
trap 'rm -rf "$work"' EXIT

Fail() {
  local label=$1
  echo "FAIL: $label" >&2
  echo "::error file=checks/check-ledger-operations.sh::$label" >&2
  exit 1
}
Compare() {
  local label=$1 actual=$2 expected=$3
  cmp "$actual" "$expected" || {
    diff -u "$expected" "$actual" >&2 || true
    Fail "$label"
  }
}

if ! ./tools/ledger-check "$fixture" >"$work/check"; then
  head -n 8 "$work/check" >&2 || true
  diagnostic=$(head -n 1 "$work/check" | head -c 300)
  echo "::error file=checks/check-ledger-operations.sh::canonical ledger-check failed: $diagnostic" >&2
  exit 1
fi
Compare 'canonical ledger-check output mismatch' "$work/check" "$fixture/ledger_check.destination.txt"
./tools/ledger-inspect "$fixture" >"$work/inspect" || Fail 'canonical ledger-inspect failed'
Compare 'canonical ledger-inspect output mismatch' "$work/inspect" "$fixture/ledger_inspect.destination.txt"

cp -R "$fixture" "$work/invalid-issues"
printf 'bad\theader\n' >"$work/invalid-issues/issues.tsv"
if ./tools/ledger-check "$work/invalid-issues" >"$work/invalid-issues.out" 2>&1; then
  Fail 'ledger-check accepted invalid canonical Issues'
fi
grep -F 'issue_header_invalid' "$work/invalid-issues.out" >/dev/null || Fail 'invalid canonical Issues diagnostic missing'
! grep -F $'ledger_check\tstate\tok' "$work/invalid-issues.out" >/dev/null || Fail 'invalid canonical Issues published ok state'

cp -R "$fixture" "$work/invalid-report"
printf '[query]\nunknown = "value"\n' >"$work/invalid-report/report.toml"
if ./tools/ledger-check "$work/invalid-report" >"$work/invalid-report.out" 2>&1; then
  Fail 'ledger-check accepted invalid canonical Report policy'
fi
! grep -F $'ledger_check\tstate\tok' "$work/invalid-report.out" >/dev/null || Fail 'invalid canonical Report policy published ok state'

cp -R "$fixture" "$work/unstable-current-envelope"
cat >>"$work/unstable-current-envelope/envelope.toml" <<'EOF'

[[envelopes]]
id = "not-in-history"
label = "Missing stable identity"
pacing = "daily"
backing-pool = "cash"
EOF
if ./tools/ledger-check "$work/unstable-current-envelope" >"$work/unstable-current-envelope.out" 2>&1; then
  Fail 'ledger-check accepted a current Envelope absent from stable history'
fi
grep -F 'current_envelope_identity_missing' "$work/unstable-current-envelope.out" >/dev/null \
  || Fail 'missing current/stable Envelope compatibility diagnostic'

if ./tools/ledger-check "$fixture" legacy-source >/dev/null 2>&1; then
  Fail 'ledger-check accepted a legacy source coordinate'
fi
if ./tools/ledger-inspect "$fixture" legacy-source >/dev/null 2>&1; then
  Fail 'ledger-inspect accepted a legacy source coordinate'
fi

if bqn src/application/report_selection_cli.bqn all human | grep -Eq '^(check|debug)$'; then
  Fail 'operational command leaked into report catalog'
fi
if rg -n 'src/sections|src_next|report_destination_cli' \
  src/application/ledger_check_cli.bqn src/application/ledger_inspect_cli.bqn tools/ledger-check tools/ledger-inspect >/dev/null; then
  Fail 'operational command imports report/runtime owner'
fi
if rg -n 'accounts\.tsv|plan\.tsv|budget_alloc\.tsv|cycle\.tsv|daily_target_scope\.tsv|config\.tsv|journalCoordinate|planCoordinate|budgetCoordinate|cycleCoordinate|issueCoordinate|dailyCoordinate' \
  src/application/ledger_check_cli.bqn src/application/ledger_inspect_cli.bqn tools/ledger-check tools/ledger-inspect; then
  Fail 'operational command still exposes a retired Household source coordinate'
fi

# Readiness is one admitted Account observation. Plan companion must
# reuse the Account Registry supplied by the already-admitted Actual observation.
grep -Fq 'planResult ← planSource.LoadFromAccounts ⟨base,accounts,registry⟩' src/application/report_source_adapter.bqn \
  || Fail 'HouseholdContext re-reads Accounts instead of sharing the readiness observation'
grep -Fq 'CanonicalEntitlement ⟨base,context.envelope_history,registry⟩' src/application/report_source_adapter.bqn \
  || Fail 'Companions does not load entitlement'
if grep -Fq '↩' src/application/report_source_adapter.bqn; then
  Fail 'Report source adapter reintroduced mutable result or diagnostic staging'
fi

echo 'check-ledger-operations: OK'
