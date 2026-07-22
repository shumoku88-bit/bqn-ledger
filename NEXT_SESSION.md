# Next session

Status: selected finite production-adjacent explicit-path writer plan
Owner: journal source migration / editor
Canonical: no; canonical routing remains `TODO.md`
Exit: focused implementation, review, completion archive, and explicit return to no selected Journal slice; no later slice may be selected automatically
Date: 2026-07-22

## Selected next goal

The owner selected native multi-posting Journal entry as the next finite Journal goal.

Canonical plan: `docs/JOURNAL_NATIVE_MULTI_POSTING_APPEND_EDITOR_PLAN.md`.

Canonical finite question:

> TSVの既存`journal add`経路、production report routing、およびTSV source truthを変更せず、明示指定された既存のMinimal BQN Journalファイルへ、一つのactual-layer取引を複数の明示的postingを持つnative Journalブロックとしてpreview・検証・atomic appendし、stale write、重複event-id、不均衡、未知勘定、無効日付・金額、および追記後検証失敗をfail-closedで拒否できる、独立したeditor経路を定義できるか。

Selected future command:

```bash
tools/edit --base DIR journal-block add \
  --journal-file FILE \
  --date YYYY-MM-DD \
  --description DESCRIPTION \
  --event-id EVENT_ID \
  --posting ACCOUNT=SIGNED_INTEGER \
  --posting ACCOUNT=SIGNED_INTEGER \
  [--posting ACCOUNT=SIGNED_INTEGER ...] \
  [--dry-run] [--yes] [--post-check none|lint|full]
```

## Routing boundaries

- `tools/edit journal add` remains the existing TSV-only `from / to / amount` writer.
- The selected command is separate and requires an explicit existing relative `.journal` target inside `--base`.
- Actual layer, `*`, JPY, durable event ID, exact signed integers, at least two ordered postings, and exact zero balance are fixed for this first writer slice.
- Existing and proposed full Journal content must pass the existing Stage 1 parser and checked Stage 2A Posting IR path against `accounts.tsv`.
- Atomic append retains pre-preview snapshot, two stale checks, backup, temporary-file construction, atomic rename, post-write digest, mandatory native validation, and guarded rollback.
- `src_edit/journal_source_check.bqn` remains TSV-only; future native post-check ownership belongs to `src_edit/journal_native_source_check.bqn`.
- No production `BuildContext`/report route, default source, TSV writer, synchronization, cutover, private data, plan/budget layer, correction policy, or TUI is selected.
- TSV remains the sole production source truth and default write path.

Exit requires focused implementation, review, completion archive, deletion of the current-path plan, and return to **no selected Journal slice**. No later slice may be selected automatically.
