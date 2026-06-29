#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-report-labels.sh
# Verifies that every BQN report label lookup `L "key"` has a matching
# declaration in config/report_labels.tsv.  This keeps presentation label
# externalization fail-closed instead of silently rendering missing keys.

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

labels_file="config/report_labels.tsv"
if [[ ! -f "$labels_file" ]]; then
  echo "FAIL: missing $labels_file" >&2
  exit 1
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

keys="$work_dir/declared.keys"
refs="$work_dir/referenced.keys"
ref_locs="$work_dir/referenced.tsv"
dup_keys="$work_dir/duplicate.keys"
missing="$work_dir/missing.keys"

awk -F'\t' '
  /^#/ || /^[[:space:]]*$/ { next }
  $1 == "" { next }
  { print $1 }
' "$labels_file" | sort > "$keys"

awk -F'\t' '
  /^#/ || /^[[:space:]]*$/ { next }
  $1 == "" { next }
  { count[$1]++ }
  END { for (k in count) if (count[k] > 1) print k }
' "$labels_file" | sort > "$dup_keys"

if [[ -s "$dup_keys" ]]; then
  echo "FAIL: duplicate report label keys in $labels_file" >&2
  sed 's/^/  - /' "$dup_keys" >&2
  exit 1
fi

# Extract L "..." calls from BQN sources.  Keep locations for useful diagnostics.
# The expression is intentionally narrow: report_labels.bqn exports Text as L in
# report modules; other string literals are not label references.
find src_next tests -type f -name '*.bqn' -print0 |
  xargs -0 perl -ne 'while (/\bL\s+"([^"]+)"/g) { print "$ARGV\t$1\n" }' > "$ref_locs"

cut -f2 "$ref_locs" | sort -u > "$refs"

comm -23 "$refs" "$keys" > "$missing"
if [[ -s "$missing" ]]; then
  echo "FAIL: missing report label declarations in $labels_file" >&2
  while IFS= read -r key; do
    echo "  - $key" >&2
    awk -F'\t' -v k="$key" '$2 == k { print "      " $1 }' "$ref_locs" >&2
  done < "$missing"
  exit 1
fi

ref_count="$(wc -l < "$refs" | tr -d ' ')"
key_count="$(wc -l < "$keys" | tr -d ' ')"
echo "check-report-labels: $ref_count referenced label key(s), $key_count declared key(s)" >&2
echo "OK" >&2
