#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-json-clock.XXXXXX")"
trap 'rm -rf "$work"' EXIT

# A structured Report request with an explicit observation coordinate must not
# consult the ambient system clock. Keep the fake date executable fail-closed so
# any accidental clock observation makes the request fail visibly.
cat >"$work/date" <<EOF
#!/bin/sh
echo yes >"$work/date-called"
exit 99
EOF
chmod +x "$work/date"

json_out="$(PATH="$work:$PATH" tools/report fixtures/ledger-facts-phase1-proof balances json JPY 2026-01-12)"

python3 -c 'import json, sys; json.load(sys.stdin)' <<<"$json_out"
[[ ! -e "$work/date-called" ]] || {
  echo 'FAIL: explicit JSON Report request invoked the ambient system clock' >&2
  exit 1
}

echo 'check-json-clock-independence: OK' >&2
