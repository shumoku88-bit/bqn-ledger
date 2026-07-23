#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT_DIR"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
sha_file(){ shasum -a 256 "$1"|awk '{print $1}'; }
no_backup(){ [[ ! -d "$1/.backup" ]] || ! find "$1/.backup" -type f | grep -q .; }
fixture=fixtures/journal-ordinary-actual-fallback-boundary

selector="$tmp/selector"; cp -R "$fixture" "$selector"; before="$(sha_file "$selector/actual.journal")"
bqn src_edit/journal_native_reverse_cmd.bqn "$selector" "" 2 2026-07-25 >"$tmp/selector.out"
[[ "$before" == "$(sha_file "$selector/actual.journal")" ]]; no_backup "$selector"
awk -F '\t' '$1=="OK" && $2=="REVERSE_NATIVE" && $3==2 && $4=="2026-07-23" && $5=="Ordinary purchase" && $7==2 && $8=="2026-07-25" {ok=1} END{exit !ok}' "$tmp/selector.out"
[[ "$(sed -n '2p' "$tmp/selector.out")" == 'expenses:food=-25' ]]
[[ "$(sed -n '3p' "$tmp/selector.out")" == 'assets:cash=25' ]]

dry="$tmp/dry"; cp -R "$fixture" "$dry"; before="$(sha_file "$dry/actual.journal")"
./tools/edit --base "$dry" journal reverse --index 2 --date 2026-07-25 --dry-run --yes --post-check none >/dev/null
[[ "$before" == "$(sha_file "$dry/actual.journal")" ]]; no_backup "$dry"

write="$tmp/write"; cp -R "$fixture" "$write"
printf 'mode\tfixed\nstart\t2026-07-01\nend_exclusive\t2026-08-01\n' >"$write/cycle.tsv"
cp "$write/actual.journal" "$tmp/original"
size="$(wc -c <"$tmp/original"|tr -d ' ')"; events="$(grep -Fc '; event-id:' "$write/actual.journal"||true)"
./tools/edit --base "$write" journal reverse --index 2 --date 2026-07-25 --yes --post-check lint >"$tmp/write.out"
head -c "$size" "$write/actual.journal" >"$tmp/prefix"; cmp "$tmp/original" "$tmp/prefix"
[[ "$(grep -Fc '; event-id:' "$write/actual.journal"||true)" -eq $((events+1)) ]]
grep -Fq '2026-07-25 * [reverse]Ordinary purchase' "$write/actual.journal"
grep -Fq 'Mandatory native validation: OK' "$tmp/write.out"
bqn src_edit/journal_validate_cmd.bqn "$write" >/dev/null
printf 'OK: native Journal reverse contract\n'
