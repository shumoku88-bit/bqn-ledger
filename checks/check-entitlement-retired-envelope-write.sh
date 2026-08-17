#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
fixture="$ROOT_DIR/fixtures/ledger-facts-phase1-proof"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
base="$tmp_root/household"
mkdir -p "$base"
cp -R "$fixture"/. "$base"/
rm -f "$base/budget_alloc.tsv" "$base/accounts.tsv" "$base/config.tsv"

python3 - "$base/household.toml" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text(encoding="utf-8")
text = text.replace('identities = ["food"]', 'identities = ["food", "retired"]')
p.write_text(text, encoding="utf-8")
PY

cat >>"$base/entitlement.journal" <<'EOF'

2026-01-05 transfer unallocated -> retired 10 JPY historical-retired-grant
EOF

# Historical/stable coordinates and old movements remain valid source evidence
# after the Envelope leaves current envelope.toml membership. Production reporting
# must still admit that history while presenting only current Envelopes.
./tools/ledger-check "$base" >/dev/null
./tools/report-all "$base" JPY compact 2026-01-31 >/dev/null

cp "$base/entitlement.journal" "$tmp_root/entitlement-before.journal"
if ./tools/edit --base "$base" entitlement add \
  --date 2026-01-31 --memo should-not-revive-retired-envelope \
  --from unallocated --to retired --amount 10 --dry-run \
  >"$tmp_root/out" 2>&1; then
  echo 'FAIL: Entitlement Add accepted a retired Envelope' >&2
  exit 1
fi
grep -F 'cannot write Entitlement transfer to retired Envelope: retired' "$tmp_root/out" >/dev/null

cmp -s "$tmp_root/entitlement-before.journal" "$base/entitlement.journal" || {
  echo 'FAIL: rejected retired Envelope write changed entitlement.journal' >&2
  exit 1
}
if [[ -d "$base/.backup" ]] && find "$base/.backup" -type f | grep -q .; then
  echo 'FAIL: rejected retired Envelope write created a backup' >&2
  exit 1
fi

echo 'check-entitlement-retired-envelope-write: OK'
