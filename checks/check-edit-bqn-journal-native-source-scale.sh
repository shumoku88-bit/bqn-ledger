#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
base="$tmp/scale"
cp -R fixtures/journal-native-multi-posting-editor "$base"

# Keep this witness synthetic. USD is registry-admitted with two fractional
# digits, so 1.20 and -1.2 must normalize exactly to the same calculation scale.
perl -0pi -e 's/JPY/USD/g' "$base/accounts.journal" "$base/source.journal"
cat >>"$base/source.journal" <<'EOF'

2026-07-22 * scale-witness
    ; event-id: scale-witness-001
    expenses:food:daily    1.20 USD
    assets:cash    -1.2 USD
EOF

before="$(shasum -a 256 "$base/source.journal" | awk '{print $1}')"
out="$tmp/source-check.out"
bqn src_edit/journal_native_source_check.bqn \
  "$base" "$base/source.journal" 2026-07-22 scale-witness durable scale-witness-001 1 currency=USD \
  expenses:food:daily=1.20 assets:cash=-1.2 >"$out"
after="$(shasum -a 256 "$base/source.journal" | awk '{print $1}')"

[[ "$before" == "$after" ]]
grep -Fq $'OK\tNATIVE_JOURNAL_CANDIDATE\tdurable\tscale-witness-001\t1\t2' "$out"
printf 'OK: native Journal source-check mixed-scale contract\n'
