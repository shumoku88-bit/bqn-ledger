#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
fixture="$ROOT_DIR/fixtures/ledger-facts-phase1-proof"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }
copy_fixture() {
  mkdir -p "$1"; cp -R "$fixture"/. "$1"/
  rm -f "$1/budget_alloc.tsv" "$1/accounts.tsv" "$1/config.tsv"
}
assert_sha() {
  local file="$1" expected="$2" label="$3"
  [[ "$(sha_file "$file")" == "$expected" ]] || { echo "FAIL: $label changed $file" >&2; exit 1; }
}
assert_no_backup() {
  local base="$1" label="$2"
  if [[ -d "$base/.backup" ]] && find "$base/.backup" -type f | grep -q .; then
    echo "FAIL: $label created backup" >&2
    exit 1
  fi
}

# Dry-run publishes nothing and uses the strict Entitlement format.
dry="$tmp_root/dry"
copy_fixture "$dry"
entitlement_before="$(sha_file "$dry/entitlement.journal")"
./tools/edit --base "$dry" entitlement add \
  --date 2026-01-02 --memo allocate-more-food \
  --from unallocated --to food --amount 10 --dry-run >"$tmp_root/dry.out"
assert_sha "$dry/entitlement.journal" "$entitlement_before" 'Entitlement Add dry-run'
assert_no_backup "$dry" 'Entitlement Add dry-run'
grep -F 'Target: '"$(cd -P "$dry" && pwd)"'/entitlement.journal' "$tmp_root/dry.out" >/dev/null
grep -F '2026-01-02 transfer unallocated -> food 10 JPY ; allocate-more-food' "$tmp_root/dry.out" >/dev/null

# Origin dry-run
./tools/edit --base "$dry" entitlement origin \
  --date 2026-01-01 --currency USD --memo initial-usd-stock --dry-run >"$tmp_root/origin-dry.out"
assert_sha "$dry/entitlement.journal" "$entitlement_before" 'Entitlement Origin dry-run'
grep -F '2026-01-01 origin USD ; initial-usd-stock' "$tmp_root/origin-dry.out" >/dev/null

# Native Entitlement source has memo provenance only; legacy arbitrary metadata
# options fail instead of being silently discarded.
if ./tools/edit --base "$dry" entitlement add \
  --date 2026-01-02 --memo metadata-rejected \
  --from unallocated --to food --amount 10 --meta allocation-id=legacy --dry-run \
  >"$tmp_root/meta-rejected.out" 2>&1; then
  echo 'FAIL: Entitlement Add accepted unsupported source metadata' >&2
  exit 1
fi
grep -F 'unknown Entitlement write option: --meta' "$tmp_root/meta-rejected.out" >/dev/null
assert_sha "$dry/entitlement.journal" "$entitlement_before" 'Entitlement metadata rejection'
assert_no_backup "$dry" 'Entitlement metadata rejection'

# Candidate preparation re-admits the complete proposed source, so a duplicate
# Commodity StockOrigin is rejected before publication.
duplicate_origin="$tmp_root/duplicate-origin"
copy_fixture "$duplicate_origin"
duplicate_origin_before="$(sha_file "$duplicate_origin/entitlement.journal")"
if ./tools/edit --base "$duplicate_origin" entitlement origin \
  --date 2026-01-02 --currency JPY --memo duplicate --dry-run \
  >"$tmp_root/duplicate-origin.out" 2>&1; then
  echo 'FAIL: Entitlement Origin accepted a duplicate Commodity origin' >&2
  exit 1
fi
grep -F 'entitlement_origin_duplicate' "$tmp_root/duplicate-origin.out" >/dev/null
assert_sha "$duplicate_origin/entitlement.journal" "$duplicate_origin_before" 'duplicate StockOrigin rejection'
assert_no_backup "$duplicate_origin" 'duplicate StockOrigin rejection'

# Apply appends only canonical entitlement.journal and creates one canonical backup.
apply="$tmp_root/apply"
copy_fixture "$apply"
./tools/edit --base "$apply" entitlement add \
  --date 2026-01-02 --memo allocate-more-food \
  --from unallocated --to food --amount 11 \
  --yes --post-check none >"$tmp_root/apply.out"
grep -Fx '2026-01-02 transfer unallocated -> food 11 JPY ; allocate-more-food' "$apply/entitlement.journal" >/dev/null
grep -F 'Mandatory Entitlement validation: OK' "$tmp_root/apply.out" >/dev/null
find "$apply/.backup" -type f -name 'entitlement.journal.*.bak' | grep -q .
bqn src_edit/entitlement_validate_cmd.bqn "$apply" >/dev/null
./tools/ledger-check "$apply" >/dev/null

# Exact decimals for currency
exact="$tmp_root/exact-decimal"
copy_fixture "$exact"
python3 - "$exact" <<'PY'
from pathlib import Path
import sys
base = Path(sys.argv[1])
h = base / "household.toml"
htext = h.read_text(encoding="utf-8").replace('identities = ["food"]', 'identities = ["food", "usd-env"]')
h.write_text(htext, encoding="utf-8")
e = base / "envelope.toml"
etext = e.read_text(encoding="utf-8") + '\n[[envelopes]]\nid = "usd-env"\nlabel = "USD Env"\npacing = "daily"\nbacking-pool = "cash"\n'
e.write_text(etext, encoding="utf-8")
PY
./tools/edit --base "$exact" entitlement origin \
  --date 2026-01-01 --memo exact-usd --currency USD \
  --yes --post-check none >/dev/null
./tools/edit --base "$exact" entitlement add \
  --date 2026-01-02 --memo exact-usd \
  --from unallocated --to usd-env --amount 12.34 --currency USD \
  --yes --post-check none >/dev/null
grep -F '2026-01-01 origin USD ; exact-usd' "$exact/entitlement.journal" >/dev/null
grep -F '2026-01-02 transfer unallocated -> usd-env 12.34 USD ; exact-usd' "$exact/entitlement.journal" >/dev/null
./tools/ledger-check "$exact" >/dev/null

expect_fail_closed() {
  local name="$1"; shift
  local base="$tmp_root/fail-$name" out="$tmp_root/fail-$name.out"
  copy_fixture "$base"
  local canonical_before
  canonical_before="$(sha_file "$base/entitlement.journal")"
  if ./tools/edit --base "$base" entitlement add "$@" >"$out" 2>&1; then
    echo "FAIL: canonical Entitlement Add accepted negative case: $name" >&2
    cat "$out" >&2
    exit 1
  fi
  assert_sha "$base/entitlement.journal" "$canonical_before" "$name canonical Entitlement"
  assert_no_backup "$base" "$name"
}

expect_fail_closed unknown-to \
  --date 2026-01-02 --memo bad --from unallocated --to missing --amount 10 --yes --post-check none
expect_fail_closed same-endpoint \
  --date 2026-01-02 --memo bad --from food --to food --amount 10 --yes --post-check none
expect_fail_closed bad-date \
  --date not-a-date --memo bad --from unallocated --to food --amount 10 --yes --post-check none
expect_fail_closed bad-amount \
  --date 2026-01-02 --memo bad --from unallocated --to food --amount 12x --yes --post-check none
expect_fail_closed zero-amount \
  --date 2026-01-02 --memo bad --from unallocated --to food --amount 0 --yes --post-check none
expect_fail_closed negative-amount \
  --date 2026-01-02 --memo bad --from unallocated --to food --amount -10 --yes --post-check none

# The fixture is canonical-only: legacy files are absent.
canonical_only="$tmp_root/canonical-only"
copy_fixture "$canonical_only"
./tools/edit-bqn --base "$canonical_only" entitlement add \
  --date 2026-01-02 --memo canonical-only \
  --from unallocated --to food --amount 12 --dry-run >/dev/null

# An already-invalid canonical Household is not a writable publication base.
invalid_household="$tmp_root/invalid-household"
copy_fixture "$invalid_household"
entitlement_before="$(sha_file "$invalid_household/entitlement.journal")"
printf '[query]\nunknown = "value"\n' >"$invalid_household/report.toml"
if ./tools/edit --base "$invalid_household" entitlement add \
  --date 2026-01-02 --memo invalid-household \
  --from unallocated --to food --amount 13 \
  --yes --post-check none >"$tmp_root/invalid-household.out" 2>&1; then
  echo 'FAIL: Entitlement Add published into an invalid canonical Household' >&2
  exit 1
fi
assert_sha "$invalid_household/entitlement.journal" "$entitlement_before" 'invalid Household Entitlement'
assert_no_backup "$invalid_household" 'invalid Household Entitlement'

# Mandatory post-publication failure restores exact original Entitlement bytes.
rollback="$tmp_root/rollback"
copy_fixture "$rollback"
entitlement_before="$(sha_file "$rollback/entitlement.journal")"
if BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_ENTITLEMENT_POST_CHECK_FAIL=1 \
  ./tools/edit --base "$rollback" entitlement add \
    --date 2026-01-02 --memo rollback \
    --from unallocated --to food --amount 14 \
    --yes --post-check none >"$tmp_root/rollback.out" 2>&1; then
  echo 'FAIL: forced Entitlement post-admission failure succeeded' >&2
  exit 1
fi
assert_sha "$rollback/entitlement.journal" "$entitlement_before" 'Entitlement rollback'
grep -F 'Rollback: restored original Entitlement bytes' "$tmp_root/rollback.out" >/dev/null

# EnvelopePolicy / EnvelopeHistory is part of the Entitlement candidate observation. A concurrent
# canonical envelope change after preparation must fail before Entitlement publication.
race="$tmp_root/race"
copy_fixture "$race"
race_entitlement_before="$(sha_file "$race/entitlement.journal")"
HOOK_ENVELOPE_PATH="$race/envelope.toml"
export HOOK_ENVELOPE_PATH
mutate_envelope_before_entitlement_append() { printf '\n# concurrent envelope change\n' >>"$HOOK_ENVELOPE_PATH"; }
export -f mutate_envelope_before_entitlement_append
if BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_BEFORE_ENTITLEMENT_APPEND_HOOK=mutate_envelope_before_entitlement_append \
  ./tools/edit --base "$race" entitlement add \
    --date 2026-01-02 --memo raced \
    --from unallocated --to food --amount 15 \
    --yes --post-check none >"$tmp_root/race.out" 2>&1; then
  echo 'FAIL: Entitlement Add published from a stale Envelope observation' >&2
  exit 1
fi
assert_sha "$race/entitlement.journal" "$race_entitlement_before" 'Entitlement Envelope race fence'
assert_no_backup "$race" 'Entitlement Envelope race fence'
grep -F 'is stale; it changed during editing' "$tmp_root/race.out" >/dev/null

echo 'check-edit-bqn-entitlement-add: OK'
