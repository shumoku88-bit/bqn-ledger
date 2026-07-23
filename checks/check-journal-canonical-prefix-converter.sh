#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

tmp_root=$(mktemp -d)
trap 'rm -rf "$tmp_root"' EXIT
accounts="$tmp_root/accounts.tsv"
snapshot="$tmp_root/journal.tsv"
suffix="$tmp_root/suffix.journal"
prefix="$tmp_root/prefix.journal"
candidate="$tmp_root/candidate.journal"

printf '%s\n' \
  $'assets:public-cash\trole=asset\ttype=liquid' \
  $'expenses:public-food\trole=expense\tbudget=daily' \
  $'expenses:public-home\trole=expense' >"$accounts"
printf '%s\n' \
  '# invented public comment' \
  '' \
  $'2044-05-03\tPublic  lunch\tassets:public-cash\texpenses:public-food\t80\ttxn_id=public-pair\tcurrency=JPY' \
  $'2044-05-04\tPublic home item\tassets:public-cash\texpenses:public-home\t20\ttxn_id=public-pair' >"$snapshot"

./tools/journal-prefix convert "$accounts" "$snapshot" journal.tsv 2044-05-01 "$prefix" >"$tmp_root/convert.out"
grep -Fq $'OK\tCANONICAL_PREFIX\t2\t2\t4' "$tmp_root/convert.out"
grep -Fq '2044-05-03 * Public  lunch' "$prefix"
grep -Fq '; event-id: legacy:journal.tsv:0' "$prefix"
grep -Fq '; event-id: legacy:journal.tsv:1' "$prefix"
[[ $(tail -c 1 "$prefix" | od -An -t x1 | tr -d ' ') == 0a ]]

set +e
./tools/journal-prefix convert "$accounts" "$snapshot" journal.tsv 2044-05-01 "$prefix" >"$tmp_root/existing.out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]]
grep -Fq 'output already exists' "$tmp_root/existing.out"

bad_snapshot="$tmp_root/bad.tsv"
bad_output="$tmp_root/bad-prefix.journal"
printf '%s\n' $'2044-05-03\ttrailing \tassets:public-cash\texpenses:public-food\t80' >"$bad_snapshot"
set +e
./tools/journal-prefix convert "$accounts" "$bad_snapshot" journal.tsv 2044-05-01 "$bad_output" >"$tmp_root/bad.out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]]
[[ ! -e $bad_output ]]
grep -Fq 'description_not_canonically_representable' "$tmp_root/bad.out"

cat >"$suffix" <<'EOF'

2044-05-05 * Native public split
    ; event-id: native-public-suffix-001
    ; layer: actual
    expenses:public-food 30 JPY
    expenses:public-home 20 JPY
    assets:public-cash -50 JPY
EOF
./tools/journal-prefix reconstruct "$accounts" "$snapshot" journal.tsv 2044-05-01 "$prefix" "$suffix" "$candidate" >"$tmp_root/reconstruct.out"
grep -Fq $'OK\tRECONSTRUCTED_CANDIDATE\t3\t7' "$tmp_root/reconstruct.out"
prefix_size=$(wc -c <"$prefix" | tr -d ' ')
suffix_size=$(wc -c <"$suffix" | tr -d ' ')
[[ $(wc -c <"$candidate" | tr -d ' ') -eq $((prefix_size + suffix_size)) ]]
cmp -s "$prefix" <(head -c "$prefix_size" "$candidate")
cmp -s "$suffix" <(tail -c "$suffix_size" "$candidate")
[[ $(grep -Fc 'native-public-suffix-001' "$candidate") -eq 1 ]]

race_target="$tmp_root/race-prefix.journal"
race_hook() { printf '%s\n' 'concurrent-winner' >"$RACE_TARGET"; }
export -f race_hook
export RACE_TARGET="$race_target"
set +e
BQN_LEDGER_TEST_MODE=1 JOURNAL_PREFIX_TEST_BEFORE_PUBLISH_HOOK=race_hook \
  ./tools/journal-prefix convert "$accounts" "$snapshot" journal.tsv 2044-05-01 "$race_target" >"$tmp_root/race.out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]]
grep -Fxq 'concurrent-winner' "$race_target"
grep -Fq 'exclusive atomic publication' "$tmp_root/race.out"

printf '%s\n' 'check-journal-canonical-prefix-converter: OK'
