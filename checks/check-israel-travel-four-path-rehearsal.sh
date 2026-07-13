#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
unset LEDGER_DATA_DIR

base="$(mktemp -d)"; trap 'rm -rf "$base"' EXIT
printf '%s\n' \
  $'assets:銀行-JPY\trole=asset\ttype=liquid\tcurrency=JPY' \
  $'assets:現金-ILS\trole=asset\ttype=liquid\tcurrency=ILS' \
  $'liabilities:カード-JPY\trole=liability\tcurrency=JPY' \
  $'expenses:食費-ILS\trole=expense\tcurrency=ILS' \
  $'expenses:交通-JPY\trole=expense\tcurrency=JPY' > "$base/accounts.tsv"
: > "$base/journal.tsv"
sha() { shasum -a 256 "$1" | awk '{print $1}'; }

exchange=(tools/edit --base "$base" travel exchange add --date 2026-07-20 --memo 'synthetic airport exchange' --source-account 'assets:銀行-JPY' --source-amount 10000 --source-currency JPY --target-account 'assets:現金-ILS' --target-amount 250.00 --target-currency ILS --exchange-id israel-2026-exchange-0001 --trip-id israel-2026)
cash=(tools/edit --base "$base" journal add --date 2026-07-20 --memo 'synthetic meal' --from 'assets:現金-ILS' --to 'expenses:食費-ILS' --amount 42.50 --currency ILS --meta trip_id=israel-2026 --meta payment=cash --post-check lint)
card=(tools/edit --base "$base" journal add --date 2026-07-20 --memo 'synthetic transit' --from 'liabilities:カード-JPY' --to 'expenses:交通-JPY' --amount 1800 --currency JPY --meta trip_id=israel-2026 --meta payment=card --post-check lint)
friend=(tools/edit --base "$base" travel friend add --date 2026-07-20 --party 'synthetic friend' --item meal --amount 35.00 --currency ILS --payer friend --trip-id israel-2026 --source-event-id israel-2026-friend-0001)

# Four public dry-runs preserve bytes and create no optional source files.
before="$(sha "$base/journal.tsv")"
"${exchange[@]}" --dry-run > "$base/exchange.dry"
"${cash[@]}" --dry-run > "$base/cash.dry"
"${card[@]}" --dry-run > "$base/card.dry"
"${friend[@]}" --dry-run > "$base/friend.dry"
[[ "$before" == "$(sha "$base/journal.tsv")" && ! -e "$base/travel_exchange_events.tsv" && ! -e "$base/friend_travel_events.tsv" ]]

# Travel-day order: exchange, ILS cash, confirmed-JPY card, friend pending.
"${exchange[@]}" --yes > "$base/exchange.out"
"${cash[@]}" --yes > "$base/cash.out"
"${card[@]}" --yes > "$base/card.out"
"${friend[@]}" --yes > "$base/friend.out"
grep -Fq 'Post-check: OK' "$base/cash.out"
grep -Fq 'Post-check: OK' "$base/card.out"
grep -Fq 'journal_source_check.bqn' "$base/card.out"

[[ "$(wc -l < "$base/journal.tsv" | tr -d ' ')" == 2 ]]
[[ "$(wc -l < "$base/travel_exchange_events.tsv" | tr -d ' ')" == 1 ]]
[[ "$(wc -l < "$base/friend_travel_events.tsv" | tr -d ' ')" == 1 ]]
grep -Fxq $'2026-07-20\tsynthetic meal\tassets:現金-ILS\texpenses:食費-ILS\t42.50\ttrip_id=israel-2026\tpayment=cash\tcurrency=ILS' "$base/journal.tsv"
grep -Fxq $'2026-07-20\tsynthetic transit\tliabilities:カード-JPY\texpenses:交通-JPY\t1800\ttrip_id=israel-2026\tpayment=card\tcurrency=JPY' "$base/journal.tsv"
grep -Fxq $'2026-07-20\tsynthetic airport exchange\tassets:銀行-JPY\t10000\tJPY\tassets:現金-ILS\t250.00\tILS\tisrael-2026-exchange-0001\tisrael-2026' "$base/travel_exchange_events.tsv"
grep -Fxq $'2026-07-20\tsynthetic friend\tmeal\t35.00\tILS\tfriend\tisrael-2026\tisrael-2026-friend-0001\tpending' "$base/friend_travel_events.tsv"
! grep -Fq 'synthetic airport exchange' "$base/journal.tsv"
! grep -Fq 'synthetic friend' "$base/journal.tsv"

# Every source reloads through its current owner.
tools/edit --base "$base" journal list --format tsv > "$base/journal.list"
[[ "$(wc -l < "$base/journal.list" | tr -d ' ')" == 2 ]]
bqn src_edit/journal_source_check.bqn "$base" >/dev/null
bqn src_edit/travel_exchange_add_cmd.bqn "$base" validate >/dev/null
bqn src_edit/travel_friend_add_cmd.bqn "$base" validate >/dev/null

# Duplicate source IDs reject with all source bytes unchanged.
journal_sha="$(sha "$base/journal.tsv")"; exchange_sha="$(sha "$base/travel_exchange_events.tsv")"; friend_sha="$(sha "$base/friend_travel_events.tsv")"
set +e
"${exchange[@]}" --yes > "$base/exchange.duplicate" 2>&1; exchange_rc=$?
"${friend[@]}" --yes > "$base/friend.duplicate" 2>&1; friend_rc=$?
set -e
[[ "$exchange_rc" -ne 0 && "$friend_rc" -ne 0 ]]
[[ "$journal_sha" == "$(sha "$base/journal.tsv")" && "$exchange_sha" == "$(sha "$base/travel_exchange_events.tsv")" && "$friend_sha" == "$(sha "$base/friend_travel_events.tsv")" ]]

# Injected journal post-check failure automatically restores exact bytes.
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_POST_CHECK_FAIL=1 tools/edit --base "$base" journal add --date 2026-07-22 --memo rollback --from 'liabilities:カード-JPY' --to 'expenses:交通-JPY' --amount 1 --currency JPY --yes --post-check lint > "$base/journal.rollback" 2>&1
rollback_rc=$?
set -e
[[ "$rollback_rc" -ne 0 && "$journal_sha" == "$(sha "$base/journal.tsv")" ]]
grep -Fq 'Rollback: restored original bytes' "$base/journal.rollback"

# Focused writers retain stale rejection; recovery check retains later-writer protection.
bash checks/check-edit-bqn-travel-friend-add.sh >/dev/null
bash checks/check-edit-bqn-travel-exchange-add.sh >/dev/null
bash checks/check-edit-bqn-journal-post-check-recovery.sh >/dev/null

! rg -n 'rate|market|valuation|finaliz|total.*JPY.*ILS|total.*ILS.*JPY' "$base/travel_exchange_events.tsv" "$base/friend_travel_events.tsv" "$base/journal.tsv"
printf 'OK: Israel travel four-path synthetic rehearsal passed (journal=2 friend=1 exchange=1)\n'
