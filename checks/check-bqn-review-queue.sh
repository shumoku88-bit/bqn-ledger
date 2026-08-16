#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

queue=TODO.md
closeout=docs/PRODUCTION_BQN_PHASE_SEVEN_CLOSEOUT-2026-08-17.md

[[ -f $queue ]] || { echo 'FAIL: BQN review queue is missing' >&2; exit 1; }
[[ -f $closeout ]] || { echo 'FAIL: production BQN Phase 7 closeout is missing' >&2; exit 1; }

grep -Fq 'The owner-by-owner production BQN review is complete as of 2026-08-17.' "$queue" \
  || { echo 'FAIL: TODO does not record completed production BQN review' >&2; exit 1; }
grep -Fq '## Current review lane' "$queue" \
  || { echo 'FAIL: TODO does not publish a current post-BQN review lane' >&2; exit 1; }
grep -Fq '## Current cursor' "$queue" \
  || { echo 'FAIL: TODO does not publish the current post-BQN cursor' >&2; exit 1; }

# The per-file cursor is finished. A future review may explicitly reopen a BQN
# lane, but the completed queue must not silently grow a hidden unchecked BQN
# cursor while claiming that the owner-by-owner pass is closed. Cross-cutting
# cursors are expected to advance and must not be frozen to one historical label.
if grep -Eq '^- \[ \] `(?:src/|src_edit/|tools/)[^`]+\.bqn`' "$queue"; then
  echo 'FAIL: completed review queue regained an unchecked production BQN cursor' >&2
  exit 1
fi

count="$(find src src_edit tools -type f -name '*.bqn' -print | wc -l | tr -d ' ')"
echo "check-bqn-review-queue: production BQN review closed over current ${count} files; post-BQN cursor may advance"
