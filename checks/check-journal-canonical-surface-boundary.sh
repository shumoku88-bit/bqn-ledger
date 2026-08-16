#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-canonical-boundary.XXXXXX")"
stage=setup
trap 'status=$?; echo "FAIL: Canonical Surface boundary stage=$stage status=$status" >&2; for f in "$work"/*.out "$work"/*.err; do [[ -f "$f" ]] && { echo "--- $f" >&2; cat "$f" >&2; }; done; exit $status' ERR
trap 'rm -rf "$work"' EXIT
base="$work/household"
mkdir -p "$base"

cat >"$base/accounts.journal" <<'EOF'
account Assets:Cash
  type: Asset
  commodity: JPY

account Expenses:Food
  type: Expense
  commodity: JPY
EOF
cat >"$base/actual.journal" <<'EOF'
2026-08-16 * lunch
    ; event-id: event-lunch
    ; layer: actual
    ; currency: JPY
    Expenses:Food 100 JPY
    Assets:Cash -100 JPY
EOF

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

source_before="$(sha256 "$base/actual.journal")"

stage=public-route
# Public editor routing graduates Canonical Surface away from the legacy
# monolithic dispatcher before any filesystem path is accepted.
grep -Fq 'exec bash "$DIR/journal-canonical-surface" "$@"' tools/edit
bash -n tools/journal-canonical-surface

stage=dot-alias
# Lexically different spelling of the canonical source must not bypass preview
# protection. The source bytes must remain untouched on every rejection.
if tools/edit --base "$base" journal canonical-surface-preview --output "$base/./actual.journal" >"$work/dot.out" 2>"$work/dot.err"; then
  echo 'FAIL: preview accepted ./ alias of canonical Journal' >&2
  exit 1
fi
[[ "$(sha256 "$base/actual.journal")" == "$source_before" ]] || {
  echo 'FAIL: ./ preview alias modified canonical Journal' >&2
  exit 1
}

stage=symlink-alias
# A final-component symlink is never an acceptable preview artifact, even when
# it points at the source through a different textual path.
ln -s "$base/actual.journal" "$work/source-link.journal"
if tools/edit --base "$base" journal canonical-surface-preview --output "$work/source-link.journal" >"$work/link.out" 2>"$work/link.err"; then
  echo 'FAIL: preview accepted symlink output alias' >&2
  exit 1
fi
[[ "$(sha256 "$base/actual.journal")" == "$source_before" ]] || {
  echo 'FAIL: symlink preview alias modified canonical Journal' >&2
  exit 1
}

stage=hardlink-alias
# Same-inode aliases are rejected independently of path spelling. This catches
# hard links that realpath/text equality alone cannot distinguish.
ln "$base/actual.journal" "$work/source-hardlink.journal"
if tools/edit --base "$base" journal canonical-surface-preview --output "$work/source-hardlink.journal" >"$work/hardlink.out" 2>"$work/hardlink.err"; then
  echo 'FAIL: preview accepted same-inode hard-link alias' >&2
  exit 1
fi
[[ "$(sha256 "$base/actual.journal")" == "$source_before" ]] || {
  echo 'FAIL: hard-link preview alias modified canonical Journal' >&2
  exit 1
}

stage=distinct-preview
# A distinct caller-owned artifact remains supported and is byte-verified by
# the BQN preview owner after semantic equivalence succeeds.
preview="$work/preview.journal"
if ! tools/edit --base "$base" journal canonical-surface-preview --output "$preview" >"$work/preview.out" 2>"$work/preview.err"; then
  cat "$work/preview.err" >&2
  false
fi
[[ -f "$preview" ]]
grep -Fq $'OK\tCANONICAL_PREVIEW\tactual.journal\t' "$work/preview.out"
grep -Fq 'Expenses:Food    100 JPY' "$preview"
if grep -Fq '; layer: actual' "$preview" || grep -Fq '; currency: JPY' "$preview"; then
  echo 'FAIL: preview retained redundant Canonical Surface metadata' >&2
  exit 1
fi
[[ "$(sha256 "$base/actual.journal")" == "$source_before" ]] || {
  echo 'FAIL: distinct preview modified canonical Journal' >&2
  exit 1
}

stage=nested-data
# The current Household root directly owns actual.journal. A historical nested
# data/actual.journal must not be recovered as an alternate writer authority.
nested="$work/nested"
mkdir -p "$nested/data"
cp "$base/actual.journal" "$nested/data/actual.journal"
if tools/edit --base "$nested" journal canonical-surface-apply --dry-run >"$work/nested.out" 2>"$work/nested.err"; then
  echo 'FAIL: Canonical Surface writer recovered historical nested data/ source' >&2
  exit 1
fi
grep -Fq 'configured Journal is not a regular file' "$work/nested.err"

stage=complete
echo 'check-journal-canonical-surface-boundary: OK'