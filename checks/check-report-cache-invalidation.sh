#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-cache-invalidation.XXXXXX")"
config_ref="$work/currencies.tsv.ref"
cp -p config/currencies.tsv "$config_ref"
cleanup() {
  touch -r "$config_ref" config/currencies.tsv 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

# Cache dependency observation must stay physical and conservative rather than
# reproducing the canonical Household/report source list in shell.
prepare_body="$(sed -n '/^prepare_cache()/,/^}/p' tools/main-ui.sh)"
grep -Fq 'find "$base_abs" -type f -print0' <<<"$prepare_body"
grep -Fq 'find "$ROOT_DIR/src" "$ROOT_DIR/config" -type f -print0' <<<"$prepare_body"
if grep -Eq 'accounts\.journal|actual\.journal|plan\.journal|budget\.journal|budget\.toml|household\.toml|report\.toml|issues\.tsv|report_labels\.tsv' <<<"$prepare_body"; then
  echo 'FAIL: main-ui cache invalidation regained a hand-maintained semantic dependency list' >&2
  exit 1
fi

cp -R fixtures/ledger-facts-phase1-proof "$work/base"
base="$work/base"
mkdir -p "$work/tmp"

# Give the full current report profile the prior/current anchors used by the
# report-cache qualification portfolio.
cat >>"$base/actual.journal" <<'EOF'

2025-12-01 cache prior income anchor
    ; event-id: cache-invalidation-prior-income
    ; layer: actual
    ; currency: JPY
    assets:cash 1 JPY
    income:salary -1 JPY

2025-12-02 cache prior income neutralization
    ; event-id: cache-invalidation-prior-neutralization
    ; layer: actual
    ; currency: JPY
    assets:cash -1 JPY
    income:salary 1 JPY
EOF
cat >>"$base/plan.journal" <<'EOF'

2026-01-02 cache historical next income
    ; plan-id: cache-invalidation-historical-income
    income:salary -1 JPY
    assets:cash 1 JPY
EOF

cache_dir="$(TMPDIR="$work/tmp" COMMAND_HUB_CACHE_REFRESH_MODE=synchronous \
  tools/main-ui.sh --base "$base" --domain JPY --latest 2026-01-12 prepare-cache)"
[[ -d "$cache_dir" && -f "$cache_dir/.cache-timestamp" ]]
generation_before="$(cat "$cache_dir/.cache-timestamp")"
[[ "$generation_before" =~ ^[0-9]+$ ]]

# Currency registry is consumed by the report application path. Changing only
# its physical observation must invalidate the preview cache even though none of
# the Household eight files changed.
sleep 1
touch config/currencies.tsv
registry_mtime=$(stat -c %Y config/currencies.tsv 2>/dev/null || stat -f %m config/currencies.tsv)
(( registry_mtime > generation_before ))

cache_dir_after="$(TMPDIR="$work/tmp" COMMAND_HUB_CACHE_REFRESH_MODE=synchronous \
  tools/main-ui.sh --base "$base" --domain JPY --latest 2026-01-12 prepare-cache)"
[[ "$cache_dir_after" == "$cache_dir" ]]
generation_after="$(cat "$cache_dir/.cache-timestamp")"
[[ "$generation_after" =~ ^[0-9]+$ ]]
(( generation_after >= registry_mtime ))
(( generation_after > generation_before ))

echo 'check-report-cache-invalidation: OK'
