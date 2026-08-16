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

cat >>"$base/accounts.journal" <<'EOF'

account budget:retired
  type: Budget
  commodity: JPY
EOF

python3 - "$base/household.toml" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text(encoding="utf-8")
text = text.replace('identities = ["food"]', 'identities = ["food", "retired"]')
text = text.replace('envelope = ["budget:food"]', 'envelope = ["budget:food", "budget:retired"]')
text += '''\n[[budget.envelopes]]\nid = "retired"\nallocation-account = "budget:retired"\n'''
p.write_text(text, encoding="utf-8")
PY

# Historical/stable coordinates are valid source evidence even when the Envelope
# is no longer active in budget.toml.
./tools/ledger-check "$base" >/dev/null

before="$(shasum -a 256 "$base/budget.journal" | awk '{print $1}')"
if ./tools/edit --base "$base" budget add \
  --date 2026-01-02 --memo should-not-revive-retired-envelope \
  --from budget:unassigned --to budget:retired --amount 10 --dry-run \
  >"$tmp_root/out" 2>&1; then
  echo 'FAIL: Budget Add accepted a retired Envelope allocation Account' >&2
  exit 1
fi
grep -F 'Budget movement cannot use retired Envelope allocation Account: budget:retired -> retired' "$tmp_root/out" >/dev/null

after="$(shasum -a 256 "$base/budget.journal" | awk '{print $1}')"
[[ "$before" == "$after" ]] || { echo 'FAIL: rejected retired Envelope write changed budget.journal' >&2; exit 1; }
if [[ -d "$base/.backup" ]] && find "$base/.backup" -type f | grep -q .; then
  echo 'FAIL: rejected retired Envelope write created a backup' >&2
  exit 1
fi

echo 'check-budget-retired-envelope-write: OK'
