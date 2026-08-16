#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# Retired src_next has no implementation directory and no dedicated diagnostic
# tool. A future import-graph tool must target current production roots instead
# of reviving a retired topology name.
[[ ! -d src_next ]]
[[ ! -e tools/src-next-import-graph ]]

# Legacy publication APIs were removed after writer-effect qualification proved
# that active callers use caller-snapshot checked/exclusive primitives.
if rg -n '^safe_(append|rewrite|create_checked)\(\)' tools/lib/safe-write.sh >/dev/null; then
  echo 'FAIL: retired safe-write API definition returned' >&2
  rg -n '^safe_(append|rewrite|create_checked)\(\)' tools/lib/safe-write.sh >&2 || true
  exit 1
fi
for current in \
  safe_snapshot_token \
  safe_create_exclusive_checked \
  safe_append_checked \
  safe_replace_line_checked \
  safe_rewrite_checked \
  safe_restore_backup_checked \
  safe_remove_created_checked; do
  grep -Eq "^${current}\\(\\)" tools/lib/safe-write.sh || {
    echo "FAIL: current safe-write primitive missing: $current" >&2
    exit 1
  }
done

# Old naming does not imply dead reachability. These two report-preview helpers
# are still current main-ui adapters and must be classified/renamed separately
# rather than removed by a broad 'command-hub' filename purge.
[[ -x tools/command-hub-cache-refresh ]]
[[ -x tools/command-hub-preview ]]
grep -Fq 'tools/command-hub-cache-refresh' tools/main-ui.sh
grep -Fq 'tools/command-hub-preview' tools/main-ui.sh

# Current public editor router remains live even though its migration-era comment
# was already replaced by the writer-effect audit.
[[ -x tools/edit ]]
grep -Fq 'exec "$DIR/edit-bqn" "$@"' tools/edit

echo 'check-dead-surface-reachability: OK'
