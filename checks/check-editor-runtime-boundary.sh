#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if rg -n 'src_next' src_edit src/editor --glob '*.bqn' >/dev/null; then
  echo 'FAIL: editor runtime still imports or names src_next' >&2; exit 1
fi
for removed in \
  src_next/journal_profile_stage1.bqn src_next/plan_status.bqn \
  src_next/travel_exchange_event.bqn src_next/friend_travel_source_event.bqn; do
  [[ ! -e $removed ]] || { echo "FAIL: moved editor owner still exists: $removed" >&2; exit 1; }
done
if rg -n '•FChars|•file|•SH|•Out|•Exit|Today|GetTime' src/editor --glob '*.bqn' >/dev/null; then
  echo 'FAIL: pure editor semantic owners gained I/O, process, or clock behavior' >&2; exit 1
fi
if rg -n 'journal_posting_ir_stage2a|account_key\.bqn|PostingRowEquivalent' \
  src_edit/journal_canonical_surface_rewrite.bqn >/dev/null; then
  echo 'FAIL: canonical rewrite retained old Posting IR/Account compatibility' >&2; exit 1
fi
if rg -n 'BuildContext|plan.tsv|budget_alloc.tsv|src_next/context' src_edit/journal_validate_cmd.bqn >/dev/null; then
  echo 'FAIL: Journal post-write validation regained unrelated context' >&2; exit 1
fi
bqn tests/test_editor_journal_profile.bqn >/dev/null
bqn tests/test_editor_travel_exchange_event.bqn >/dev/null
bqn tests/test_editor_friend_travel_source_event.bqn >/dev/null
bqn tests/test_accounting_plan_temporal_status.bqn >/dev/null

echo 'check-editor-runtime-boundary: OK'
