#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-cache-proof.XXXXXX")
trap 'rm -rf "$work"' EXIT
cp -R "$fixture" "$work/base"
base="$work/base"
cache="$work/cache"
mkdir "$cache"
printf 'retired\n' >"$cache/snapshot.txt"
printf 'retired\n' >"$cache/debug.txt"
printf 'keep\n' >"$cache/application.note"

./tools/report-cache "$base" "$cache" 101 report_all_human.destination.tsv
mapfile -t expected < <(bqn src/application/report_selection_cli.bqn all human)
printf '%s\n' "${expected[@]}" all >"$work/expected-keys"
cmp "$work/expected-keys" "$cache/.section-keys"
[[ $(cat "$cache/.cache-timestamp") == 101 ]]
[[ ! -e $cache/snapshot.txt && ! -e $cache/debug.txt && -e $cache/application.note ]]
for key in "${expected[@]}" all; do [[ -f $cache/$key.txt ]]; done
text_count=$(find "$cache" -maxdepth 1 -type f -name '*.txt' | wc -l | tr -d ' ')
[[ $text_count -eq $((${#expected[@]} + 1)) ]]
./tools/report "$base" all human report_all_human.destination.tsv >"$work/direct-all"
cmp "$work/direct-all" "$cache/all.txt"
./tools/report "$base" balances human JPY 2026-01-12 actual.journal >"$work/direct-balances"
cmp "$work/direct-balances" "$cache/balances.txt"
: >"$work/concatenated"
for key in "${expected[@]}"; do cat "$cache/$key.txt" >>"$work/concatenated"; done
cmp "$work/concatenated" "$cache/all.txt"

all_hash=$(shasum -a 256 "$cache/all.txt" | awk '{print $1}')
mkdir "$cache/.destination-cache-lock"
printf '%s\n' "$$" >"$cache/.destination-cache-lock/pid"
if ./tools/report-cache "$base" "$cache" 102 report_all_human.destination.tsv >"$work/lock.out" 2>"$work/lock.err"; then
  echo 'FAIL: concurrent cache refresh succeeded' >&2; exit 1
fi
grep -F 'cache_refresh_locked' "$work/lock.err" >/dev/null
rm -rf "$cache/.destination-cache-lock"
[[ $(cat "$cache/.cache-timestamp") == 101 ]]
{
  printf 'key\tsurface\targuments\n'
  tail -n +3 "$base/report_all_human.destination.tsv"
  sed -n '2p' "$base/report_all_human.destination.tsv"
} >"$base/bad-order.tsv"
if ./tools/report-cache "$base" "$cache" 102 bad-order.tsv >"$work/bad.out" 2>"$work/bad.err"; then
  echo 'FAIL: invalid cache manifest succeeded' >&2; exit 1
fi
grep -F 'all_manifest_order_mismatch' "$work/bad.err" >/dev/null
[[ $(cat "$cache/.cache-timestamp") == 101 ]]
[[ $(shasum -a 256 "$cache/all.txt" | awk '{print $1}') == "$all_hash" ]]
if ./tools/report-cache "$base" "$cache" invalid report_all_human.destination.tsv >"$work/token.out" 2>"$work/token.err"; then
  echo 'FAIL: invalid generation token succeeded' >&2; exit 1
fi
grep -F 'cache_generation_invalid' "$work/token.err" >/dev/null
[[ -z $(find "$cache" -maxdepth 1 -type d -name '.destination-stage.*' -print -quit) ]]

echo 'check-report-cache: OK'
