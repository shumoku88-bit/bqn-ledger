#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

queue=TODO.md
production_roots=(src src_edit tools)
cursor_scope=src/text

actual="$(mktemp)"
listed="$(mktemp)"
raw="$(mktemp)"
trap 'rm -f "$actual" "$listed" "$raw"' EXIT

find "${production_roots[@]}" -type f -name '*.bqn' -print | sort >"$actual"

sed -nE 's/^- \[[ x]\] `([^`]+\.bqn)`.*$/\1/p' "$queue" \
  | grep -E '^(src/|src_edit/|tools/)' >"$raw" || true
sort "$raw" >"$listed"

failed=0

if duplicates="$(uniq -d "$listed")" && [[ -n $duplicates ]]; then
  echo 'FAIL: duplicate production BQN review queue entries:' >&2
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
  echo 'FAIL: production BQN review queue paths that do not exist:' >&2
  printf '%s\n' "$stale" >&2
  failed=1
fi

# The cursor sequence is a navigation aid for the currently active phase only.
# Repository-wide inventory coverage must not turn later phase order into a
# topology law or block a justified cross-owner exception under D1/D6.
if ! awk -v scope="$cursor_scope/" '
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
      print "FAIL: checked item appears after an unchecked item in current cursor scope: " path > "/dev/stderr"
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
echo "check-bqn-review-queue: ${count} production BQN files covered exactly once; cursor scope ${cursor_scope} remains ordered"
