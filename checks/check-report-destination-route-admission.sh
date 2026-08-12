#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture="$root/fixtures/ledger-facts-phase1-proof"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-destination-route.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
cli="$root/src/application/report_destination_cli.bqn"
destination="$root/src/application/report_destination.bqn"

ExpectLine() {
  local expected=$1 file=$2
  grep -Fx "$expected" "$file" >/dev/null || {
    echo "FAIL: expected exact line: $expected" >&2
    cat "$file" >&2
    exit 1
  }
}

grep -F 'route ← •Import "report_route.bqn"' "$cli" >/dev/null
grep -F 'route.Admit ⟨key,surface,coordinates⟩' "$cli" >/dev/null
grep -F 'catalogIndex ← routeAdmission.catalog_index' "$cli" >/dev/null
grep -F 'catalogIndex◶evidenceLoaders' "$cli" >/dev/null
grep -F 'catalogIndex◶destinations' "$destination" >/dev/null
if grep -Eq 'Contains ←|actualKeys ←|contextKeys ←' "$cli"; then
  echo 'FAIL: destination CLI still rescans report keys for evidence lifetime' >&2
  exit 1
fi
if grep -Eq 'key≡"(envelopes|balances|balance-sheet|profit-and-loss|recent|planned|cycle-accounts|cycle-comparison|monthly-accounts|daily-flow|daily-target|issues)"' "$destination"; then
  echo 'FAIL: semantic destination still rescans admitted report keys' >&2
  exit 1
fi
if grep -Eq 'usage_(envelopes|balances|recent|planned|cycle_accounts|cycle_comparison|monthly_accounts|daily_flow|daily_target|issues)' "$cli"; then
  echo 'FAIL: destination CLI still owns individual raw route admission' >&2
  exit 1
fi
if grep -Fq 'IsDigits' "$cli"; then
  echo 'FAIL: destination CLI still owns recent LIMIT text admission' >&2
  exit 1
fi

registry_line=$(grep -n 'registryResult ← sources.Registry' "$cli" | cut -d: -f1)
route_line=$(grep -n 'routeAdmission ← route.Admit' "$cli" | cut -d: -f1)
[[ -n $registry_line && -n $route_line && $registry_line -lt $route_line ]] || {
  echo 'FAIL: individual route admission moved before registry admission' >&2
  exit 1
}

bqn "$cli" "$fixture" balances human JPY 2026-01-12 >"$tmp/balances"
cmp "$tmp/balances" "$fixture/account_balances.destination.human.txt"

# Evidence-lifetime laws use temporary reductions of the existing canonical fixture.
# They do not introduce a second fixture topology.
cp -R "$fixture" "$tmp/actual-only"
rm -f "$tmp/actual-only/plan.journal" "$tmp/actual-only/budget.journal" \
  "$tmp/actual-only/budget.toml" "$tmp/actual-only/household.toml" "$tmp/actual-only/issues.tsv"
bqn "$cli" "$tmp/actual-only" balances human JPY 2026-01-12 >"$tmp/actual-only.out"
cmp "$tmp/actual-only.out" "$fixture/account_balances.destination.human.txt"

cp -R "$fixture" "$tmp/context-only"
rm -f "$tmp/context-only/budget.journal" "$tmp/context-only/issues.tsv"
bqn "$cli" "$tmp/context-only" planned human 2026-01-12 >"$tmp/context-only.out"
[[ -s "$tmp/context-only.out" ]] || {
  echo 'FAIL: planned destination produced no output without Budget movement source' >&2
  exit 1
}

cp -R "$fixture" "$tmp/issues-only"
rm -f "$tmp/issues-only/accounts.journal" "$tmp/issues-only/actual.journal" \
  "$tmp/issues-only/plan.journal" "$tmp/issues-only/budget.journal" \
  "$tmp/issues-only/budget.toml" "$tmp/issues-only/household.toml"
bqn "$cli" "$tmp/issues-only" issues human >"$tmp/issues-only.out"
[[ -s "$tmp/issues-only.out" ]] || {
  echo 'FAIL: issues destination produced no output without accounting sources' >&2
  exit 1
}

if bqn "$cli" "$fixture" balances human JPY >"$tmp/arity" 2>&1; then
  echo 'FAIL: direct destination invalid arity succeeded' >&2
  exit 1
fi
ExpectLine $'ERROR\tusage_balances\tbalances requires DOMAIN AS_OF' "$tmp/arity"

if bqn "$cli" "$fixture" balances human JPY 2026-01-12 actual.journal >"$tmp/source" 2>&1; then
  echo 'FAIL: direct destination physical source coordinate succeeded' >&2
  exit 1
fi
ExpectLine $'ERROR\tusage_balances\tbalances requires DOMAIN AS_OF' "$tmp/source"

if bqn "$cli" "$fixture" recent human 2026-01-12 nope >"$tmp/limit" 2>&1; then
  echo 'FAIL: direct destination invalid LIMIT succeeded' >&2
  exit 1
fi
ExpectLine $'ERROR\tlimit_invalid\tLIMIT must be decimal digits' "$tmp/limit"

# Request and `all` admission remain before registry access.
if (
  cd "$tmp"
  bqn "$cli" "$fixture" unknown human >"$tmp/unknown" 2>&1
); then
  echo 'FAIL: unknown direct destination key succeeded without registry' >&2
  exit 1
fi
ExpectLine $'ERROR\treport_key_unknown\treport key is not in the retained catalog' "$tmp/unknown"

if (
  cd "$tmp"
  bqn "$cli" "$fixture" all human >"$tmp/all" 2>&1
); then
  echo 'FAIL: direct destination all succeeded without registry' >&2
  exit 1
fi
ExpectLine $'ERROR\tall_not_implemented\tparallel CLI currently requires one retained key' "$tmp/all"

echo 'check-report-destination-route-admission: OK'
