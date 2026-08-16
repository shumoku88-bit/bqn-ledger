#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

queue=TODO.md
closeout=docs/PRODUCTION_BQN_PHASE_SEVEN_CLOSEOUT-2026-08-17.md

[[ -f $queue ]] || { echo 'FAIL: BQN review queue is missing' >&2; exit 1; }
[[ -f $closeout ]] || { echo 'FAIL: production BQN Phase 7 closeout is missing' >&2; exit 1; }

grep -Fq 'The 2026-08-17 owner-by-owner production BQN review and its cross-cutting re-baseline are complete.' "$queue" \
  || { echo 'FAIL: TODO does not record completed BQN re-baseline' >&2; exit 1; }
grep -Fq '## Completed cross-cutting queue' "$queue" \
  || { echo 'FAIL: TODO does not record the completed cross-cutting queue' >&2; exit 1; }
grep -Fq 'There is no active review cursor from this re-baseline.' "$queue" \
  || { echo 'FAIL: TODO does not record the closed review cursor' >&2; exit 1; }
grep -Fq 'none — re-baseline complete' "$queue" \
  || { echo 'FAIL: TODO current cursor is not closed' >&2; exit 1; }

# The per-file cursor is finished. A future review may explicitly reopen a BQN
# lane, but the completed queue must not silently grow a hidden unchecked BQN
# cursor while claiming that the owner-by-owner pass is closed.
if grep -Eq '^- \[ \] `(?:src/|src_edit/|tools/)[^`]+\.bqn`' "$queue"; then
  echo 'FAIL: completed review queue regained an unchecked production BQN cursor' >&2
  exit 1
fi

count="$(find src src_edit tools -type f -name '*.bqn' -print | wc -l | tr -d ' ')"
echo "check-bqn-review-queue: production BQN review and cross-cutting re-baseline closed over current ${count} files"
