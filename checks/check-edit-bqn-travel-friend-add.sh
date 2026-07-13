#!/usr/bin/env bash
set -euo pipefail

# Covers src_edit/travel_friend_add_cmd.bqn through the public editor boundary.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
unset LEDGER_DATA_DIR

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
sha() { shasum -a 256 "$1" | awk '{print $1}'; }
cmd=(tools/edit --base "$tmp/base" travel friend add --date 2026-07-20 --party 'synthetic friend' --item meal --amount 42.50 --currency ILS --payer friend --trip-id israel-2026 --source-event-id israel-2026-friend-0001)
mkdir "$tmp/base"

# Dry-run does not bootstrap the optional source.
"${cmd[@]}" --dry-run >"$tmp/dry.out"
[[ ! -e "$tmp/base/friend_travel_events.tsv" ]]
grep -Fq 'Dry-run only' "$tmp/dry.out"

# Explicit --yes performs exclusive first-file creation with exactly one row.
"${cmd[@]}" --yes >"$tmp/first.out"
target="$tmp/base/friend_travel_events.tsv"
[[ "$(wc -l < "$target" | tr -d ' ')" == 1 ]]
grep -Fxq $'2026-07-20\tsynthetic friend\tmeal\t42.50\tILS\tfriend\tisrael-2026\tisrael-2026-friend-0001\tpending' "$target"
grep -Fq 'Backup: none (exclusive first-file creation)' "$tmp/first.out"
grep -Fq 'Event ID: israel-2026-friend-0001' "$tmp/first.out"

# A second event appends exactly once and creates recoverable evidence.
tools/edit --base "$tmp/base" travel friend add --date 2026-07-21 --party 'synthetic friend' --item transit --amount 3.25 --currency ILS --payer friend --trip-id israel-2026 --source-event-id israel-2026-friend-0002 --yes >"$tmp/second.out"
[[ "$(wc -l < "$target" | tr -d ' ')" == 2 ]]
backup="$(awk -F': ' '$1=="Backup" {print $2}' "$tmp/second.out")"
[[ -f "$backup" ]]

expect_fail_unchanged() {
  local label="$1" base="$2"; shift 2
  local file="$base/friend_travel_events.tsv" before after rc
  before="$(sha "$file")"
  set +e
  tools/edit --base "$base" travel friend add "$@" --yes >"$tmp/$label.out" 2>&1
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] || { echo "FAIL: $label succeeded" >&2; exit 1; }
  after="$(sha "$file")"
  [[ "$before" == "$after" ]] || { echo "FAIL: $label changed source" >&2; exit 1; }
}

common=(--date 2026-07-22 --party friend --item item --amount 1 --currency ILS --payer friend --trip-id israel-2026 --source-event-id new-id)
expect_fail_unchanged duplicate "$tmp/base" --date 2026-07-22 --party friend --item item --amount 1 --currency ILS --payer friend --trip-id israel-2026 --source-event-id israel-2026-friend-0001
expect_fail_unchanged invalid-amount "$tmp/base" --date 2026-07-22 --party friend --item item --amount 0 --currency ILS --payer friend --trip-id israel-2026 --source-event-id bad-amount
expect_fail_unchanged precision "$tmp/base" --date 2026-07-22 --party friend --item item --amount 1.001 --currency ILS --payer friend --trip-id israel-2026 --source-event-id precision
expect_fail_unchanged currency "$tmp/base" --date 2026-07-22 --party friend --item item --amount 1 --currency JPY --payer friend --trip-id israel-2026 --source-event-id currency
expect_fail_unchanged payer "$tmp/base" --date 2026-07-22 --party friend --item item --amount 1 --currency ILS --payer self --trip-id israel-2026 --source-event-id payer
expect_fail_unchanged trip "$tmp/base" --date 2026-07-22 --party friend --item item --amount 1 --currency ILS --payer friend --trip-id other --source-event-id trip
expect_fail_unchanged tab "$tmp/base" --date 2026-07-22 --party $'bad\tparty' --item item --amount 1 --currency ILS --payer friend --trip-id israel-2026 --source-event-id tab
expect_fail_unchanged newline "$tmp/base" --date 2026-07-22 --party friend --item $'bad\nitem' --amount 1 --currency ILS --payer friend --trip-id israel-2026 --source-event-id newline

# Any malformed existing data row closes the whole append path.
malformed="$tmp/malformed"; mkdir "$malformed"; printf 'malformed\trow\n' > "$malformed/friend_travel_events.tsv"
expect_fail_unchanged malformed "$malformed" "${common[@]}"

# A stale source change is retained, but the candidate and backup are absent.
stale="$tmp/stale"; mkdir "$stale"; cp "$target" "$stale/friend_travel_events.tsv"
stale_hook() { printf '%s\n' '# synthetic concurrent edit' >> "$EDIT_BQN_TEST_STALE_FRIEND"; }
export -f stale_hook
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_STALE_FRIEND="$stale/friend_travel_events.tsv" EDIT_BQN_TEST_BEFORE_APPEND_HOOK=stale_hook \
  tools/edit --base "$stale" travel friend add "${common[@]}" --yes >"$tmp/stale.out" 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]]
! grep -Fq $'\tnew-id\t' "$stale/friend_travel_events.tsv"
tail -n 1 "$stale/friend_travel_events.tsv" | grep -Fxq '# synthetic concurrent edit'
[[ ! -d "$stale/.backup" ]]

# Dedicated post-check failure restores the exact pre-write bytes.
rollback="$tmp/rollback"; mkdir "$rollback"; cp "$target" "$rollback/friend_travel_events.tsv"
before="$(sha "$rollback/friend_travel_events.tsv")"
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FRIEND_POST_CHECK_FAIL=1 \
  tools/edit --base "$rollback" travel friend add "${common[@]}" --yes >"$tmp/rollback.out" 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 && "$before" == "$(sha "$rollback/friend_travel_events.tsv")" ]]
grep -Fq 'Rollback: OK' "$tmp/rollback.out"

# Concurrent first-write cannot replace the winner.
race="$tmp/race"; mkdir "$race"
winner=$'2026-07-19\twinner\tmeal\t1\tILS\tfriend\tisrael-2026\twinner-id\tpending'
race_hook() { printf '%s\n' "$FRIEND_RACE_WINNER" > "$FRIEND_RACE_TARGET"; }
export -f race_hook
set +e
BQN_LEDGER_TEST_MODE=1 SAFE_WRITE_TEST_BEFORE_EXCLUSIVE_CREATE_HOOK=race_hook FRIEND_RACE_WINNER="$winner" FRIEND_RACE_TARGET="$race/friend_travel_events.tsv" \
  tools/edit --base "$race" travel friend add "${common[@]}" --yes >"$tmp/race.out" 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]]
[[ "$(cat "$race/friend_travel_events.tsv")" == "$winner" ]]
! find "$race" -name '*.tmp-*' -print -quit | grep -q .

# Interrupted first-write leaves neither a source nor staged partial file.
interrupted="$tmp/interrupted"; mkdir "$interrupted"
interrupt_hook() { return 77; }
export -f interrupt_hook
set +e
BQN_LEDGER_TEST_MODE=1 SAFE_WRITE_TEST_BEFORE_EXCLUSIVE_CREATE_HOOK=interrupt_hook \
  tools/edit --base "$interrupted" travel friend add "${common[@]}" --yes >"$tmp/interrupted.out" 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 && ! -e "$interrupted/friend_travel_events.tsv" ]]
! find "$interrupted" -name '*.tmp-*' -print -quit | grep -q .

# The editor never creates a missing base directory.
set +e
tools/edit --base "$tmp/missing/base" travel friend add "${common[@]}" --yes >"$tmp/missing.out" 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 && ! -e "$tmp/missing" ]]

printf 'OK: friend travel pending source-event safe append checks passed\n'
