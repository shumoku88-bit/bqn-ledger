#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

queue=TODO.md
scope=src/accounting

actual="$(mktemp)"
listed="$(mktemp)"
raw="$(mktemp)"
trap 'rm -f "$actual" "$listed" "$raw"' EXIT

find "$scope" -maxdepth 1 -type f -name '*.bqn' -print | sort >"$actual"

sed -nE 's/^- \[[ x]\] `([^`]+\.bqn)`.*$/\1/p' "$queue" \
  | grep "^${scope}/" >"$raw" || true
sort "$raw" >"$listed"

failed=0

if duplicates="$(uniq -d "$listed")" && [[ -n $duplicates ]]; then
  echo 'FAIL: duplicate BQN review queue entries:' >&2
  printf '%s\n' "$duplicates" >&2
  failed=1
fi

missing="$(comm -23 "$actual" "$listed")"
if [[ -n $missing ]]; then
  echo 'FAIL: production BQN files missing from the review queue:' >&2
  printf '%s\n' "$missing" >&2
  failed=1
fi

stale="$(comm -13 "$actual" "$listed")"
if [[ -n $stale ]]; then
  echo 'FAIL: review queue paths that do not exist in the current phase:' >&2
  printf '%s\n' "$stale" >&2
  failed=1
fi

if ! awk -v scope="$scope/" '
  /^- \[[ x]\] `[^`]+\.bqn`/ {
    line=$0
    first=index(line, "`")
    rest=substr(line, first+1)
    second=index(rest, "`")
    path=substr(rest, 1, second-1)
    if (index(path, scope) != 1) next
    checked = line ~ /^- \[x\]/
    if (!checked) pending=1
    if (checked && pending) {
      print "FAIL: checked item appears after an unchecked item: " path > "/dev/stderr"
      bad=1
    }
  }
  END { exit bad }
' "$queue"; then
  failed=1
fi

if [[ $failed -ne 0 ]]; then
  exit 1
fi

count="$(wc -l <"$actual" | tr -d ' ')"
echo "check-bqn-review-queue: ${count} ${scope} files covered exactly once"
