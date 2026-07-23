#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
unset LEDGER_DATA_DIR

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
sha() { shasum -a 256 "$1" | awk '{print $1}'; }
mkdir "$tmp/base"
printf '%s\n' $'assets:bank-jpy\trole=asset\tcurrency=JPY' $'assets:cash-ils\trole=asset\tcurrency=ILS' > "$tmp/base/accounts.tsv"
printf 'sentinel journal bytes\n' > "$tmp/base/actual.journal"
journal_before="$(sha "$tmp/base/actual.journal")"
common=(--date 2026-07-20 --memo 'airport exchange' --source-account assets:bank-jpy --source-amount 10000 --source-currency JPY --target-account assets:cash-ils --target-amount 250.00 --target-currency ILS --exchange-id israel-2026-exchange-0001 --trip-id israel-2026)

# Dry-run preserves every source byte and creates no exchange source.
tools/edit --base "$tmp/base" travel exchange add "${common[@]}" --dry-run >"$tmp/dry.out"
[[ ! -e "$tmp/base/travel_exchange_events.tsv" && "$journal_before" == "$(sha "$tmp/base/actual.journal")" ]]
grep -Fq $'10000\tJPY\tassets:cash-ils\t250.00\tILS' "$tmp/dry.out"

# Exclusive first-write keeps both observed amounts and no journal projection.
tools/edit --base "$tmp/base" travel exchange add "${common[@]}" --yes >"$tmp/first.out"
target="$tmp/base/travel_exchange_events.tsv"
row=$'2026-07-20\tairport exchange\tassets:bank-jpy\t10000\tJPY\tassets:cash-ils\t250.00\tILS\tisrael-2026-exchange-0001\tisrael-2026'
grep -Fxq "$row" "$target"
[[ "$(wc -l < "$target" | tr -d ' ')" == 1 && "$journal_before" == "$(sha "$tmp/base/actual.journal")" ]]
grep -Fq 'Exchange ID: israel-2026-exchange-0001' "$tmp/first.out"

# Second exact append creates backup evidence.
second=(--date 2026-07-21 --memo second --source-account assets:bank-jpy --source-amount 5000 --source-currency JPY --target-account assets:cash-ils --target-amount 125.50 --target-currency ILS --exchange-id israel-2026-exchange-0002 --trip-id israel-2026)
tools/edit --base "$tmp/base" travel exchange add "${second[@]}" --yes >"$tmp/second.out"
[[ "$(wc -l < "$target" | tr -d ' ')" == 2 ]]
[[ -f "$(awk -F': ' '$1=="Backup" {print $2}' "$tmp/second.out")" ]]

expect_fail_unchanged() {
  local label="$1" base="$2"; shift 2
  local file="$base/travel_exchange_events.tsv" before rc
  before="$(sha "$file")"; set +e
  tools/edit --base "$base" travel exchange add "$@" --yes >"$tmp/$label.out" 2>&1; rc=$?
  set -e
  [[ "$rc" -ne 0 && "$before" == "$(sha "$file")" ]] || { echo "FAIL: $label changed source or succeeded" >&2; exit 1; }
}
expect_fail_unchanged duplicate "$tmp/base" "${common[@]}"
expect_fail_unchanged reversed "$tmp/base" --date 2026-07-22 --memo bad --source-account assets:cash-ils --source-amount 1 --source-currency ILS --target-account assets:bank-jpy --target-amount 1 --target-currency JPY --exchange-id reversed --trip-id israel-2026
expect_fail_unchanged unknown "$tmp/base" --date 2026-07-22 --memo bad --source-account unknown --source-amount 1 --source-currency JPY --target-account assets:cash-ils --target-amount 1 --target-currency ILS --exchange-id unknown --trip-id israel-2026
expect_fail_unchanged zero "$tmp/base" --date 2026-07-22 --memo bad --source-account assets:bank-jpy --source-amount 0 --source-currency JPY --target-account assets:cash-ils --target-amount 1 --target-currency ILS --exchange-id zero --trip-id israel-2026
expect_fail_unchanged jpy-precision "$tmp/base" --date 2026-07-22 --memo bad --source-account assets:bank-jpy --source-amount 1.5 --source-currency JPY --target-account assets:cash-ils --target-amount 1 --target-currency ILS --exchange-id jpy-precision --trip-id israel-2026
expect_fail_unchanged ils-precision "$tmp/base" --date 2026-07-22 --memo bad --source-account assets:bank-jpy --source-amount 1 --source-currency JPY --target-account assets:cash-ils --target-amount 1.001 --target-currency ILS --exchange-id ils-precision --trip-id israel-2026
expect_fail_unchanged control "$tmp/base" --date 2026-07-22 --memo $'bad\tmemo' --source-account assets:bank-jpy --source-amount 1 --source-currency JPY --target-account assets:cash-ils --target-amount 1 --target-currency ILS --exchange-id control --trip-id israel-2026

# Malformed existing source closes the entire path.
malformed="$tmp/malformed"; mkdir "$malformed"; cp "$tmp/base/accounts.tsv" "$malformed/accounts.tsv"; printf 'bad\trow\n' > "$malformed/travel_exchange_events.tsv"
expect_fail_unchanged malformed "$malformed" "${second[@]}"

# Stale append rejects candidate without backup; concurrent marker remains.
stale="$tmp/stale"; mkdir "$stale"; cp "$tmp/base/accounts.tsv" "$stale/accounts.tsv"; cp "$target" "$stale/travel_exchange_events.tsv"
stale_exchange_hook() { printf '%s\n' '# synthetic concurrent edit' >> "$EXCHANGE_STALE_TARGET"; }
export -f stale_exchange_hook
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_BEFORE_APPEND_HOOK=stale_exchange_hook EXCHANGE_STALE_TARGET="$stale/travel_exchange_events.tsv" tools/edit --base "$stale" travel exchange add --date 2026-07-22 --memo stale --source-account assets:bank-jpy --source-amount 1 --source-currency JPY --target-account assets:cash-ils --target-amount 1 --target-currency ILS --exchange-id stale-id --trip-id israel-2026 --yes >"$tmp/stale.out" 2>&1; rc=$?
set -e
[[ "$rc" -ne 0 ]]; ! grep -Fq $'\tstale-id\t' "$stale/travel_exchange_events.tsv"; [[ ! -d "$stale/.backup" ]]

# Injected post-check failure rolls an existing source back byte-exactly.
rollback="$tmp/rollback"; mkdir "$rollback"; cp "$tmp/base/accounts.tsv" "$rollback/accounts.tsv"; cp "$target" "$rollback/travel_exchange_events.tsv"; before="$(sha "$rollback/travel_exchange_events.tsv")"
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_EXCHANGE_POST_CHECK_FAIL=1 tools/edit --base "$rollback" travel exchange add --date 2026-07-22 --memo rollback --source-account assets:bank-jpy --source-amount 1 --source-currency JPY --target-account assets:cash-ils --target-amount 1 --target-currency ILS --exchange-id rollback-id --trip-id israel-2026 --yes >"$tmp/rollback.out" 2>&1; rc=$?
set -e
[[ "$rc" -ne 0 && "$before" == "$(sha "$rollback/travel_exchange_events.tsv")" ]]; grep -Fq 'Rollback: OK' "$tmp/rollback.out"

# Concurrent and interrupted first-write leave no partial candidate.
winner=$'2026-07-19\twinner\tassets:bank-jpy\t1\tJPY\tassets:cash-ils\t1\tILS\twinner-id\tisrael-2026'
race="$tmp/race"; mkdir "$race"; cp "$tmp/base/accounts.tsv" "$race/accounts.tsv"
race_hook() { printf '%s\n' "$EXCHANGE_WINNER" > "$EXCHANGE_RACE_TARGET"; }; export -f race_hook
set +e
BQN_LEDGER_TEST_MODE=1 SAFE_WRITE_TEST_BEFORE_EXCLUSIVE_CREATE_HOOK=race_hook EXCHANGE_WINNER="$winner" EXCHANGE_RACE_TARGET="$race/travel_exchange_events.tsv" tools/edit --base "$race" travel exchange add "${common[@]}" --yes >"$tmp/race.out" 2>&1; rc=$?
set -e
[[ "$rc" -ne 0 && "$(cat "$race/travel_exchange_events.tsv")" == "$winner" ]]
interrupted="$tmp/interrupted"; mkdir "$interrupted"; cp "$tmp/base/accounts.tsv" "$interrupted/accounts.tsv"
interrupt_hook() { return 77; }; export -f interrupt_hook
set +e
BQN_LEDGER_TEST_MODE=1 SAFE_WRITE_TEST_BEFORE_EXCLUSIVE_CREATE_HOOK=interrupt_hook tools/edit --base "$interrupted" travel exchange add "${common[@]}" --yes >"$tmp/interrupted.out" 2>&1; rc=$?
set -e
[[ "$rc" -ne 0 && ! -e "$interrupted/travel_exchange_events.tsv" ]]; ! find "$interrupted" -name '*.tmp-*' -print -quit | grep -q .

[[ "$journal_before" == "$(sha "$tmp/base/actual.journal")" ]]
printf 'OK: Israel exchange source-event safe append checks passed\n'
