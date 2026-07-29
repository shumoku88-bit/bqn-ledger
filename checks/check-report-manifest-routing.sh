#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
config="$fixture/report_manifests.destination.tsv"
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-report-manifest-routing.XXXXXX")
trap 'rm -rf "$work"' EXIT

human=$(bqn src/application/report_manifest_config_cli.bqn "$config" human)
compact=$(bqn src/application/report_manifest_config_cli.bqn "$config" compact)
./tools/report-destination "$fixture" balances human --manifest "$human" >"$work/balances"
cmp "$work/balances" "$fixture/account_balances.destination.human.txt"
./tools/report-destination "$fixture" all human "$human" >"$work/all"
./tools/report-summary "$fixture" "$fixture/$compact" >"$work/summary"
cmp "$work/summary" "$fixture/report_summary.destination.txt"
./tools/report-destination-cache "$fixture" "$work/cache" 1 "$human"
cmp "$work/cache/balances.txt" "$work/balances"
cmp "$work/cache/all.txt" "$work/all"
[[ $(cat "$work/cache/.cache-timestamp") == 1 ]]

if bqn src/application/report_manifest_config_cli.bqn "$config" json >"$work/json" 2>&1; then
  echo 'FAIL: unsupported configured manifest surface succeeded' >&2; exit 1
fi
grep -F $'ERROR\tsurface' "$work/json" >/dev/null

echo 'check-report-manifest-routing: OK'
