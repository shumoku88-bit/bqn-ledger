# Next session

Status: selected finite production-adjacent read-only plan
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: focused public-synthetic implementation, review, completion record, and return to no selected finite Journal slice
Date: 2026-07-22

## Current state

Selected finite production-adjacent read-only plan: `docs/JOURNAL_FILE_BACKED_SHADOW_CONTEXT_PLAN.md`.

Selected shadow path:

```text
explicit Journal path
  -> file-backed read-only load
  -> Journal carrier
  -> Transaction IR
  -> checked Posting IR
  -> BuildPeriodView
  -> shadow context
  -> actual-layer TSV parity
```

## Production boundary

Production Journal routing, writer/editor work, envelope/report runtime migration, private data, source conversion, cutover, reverse synchronization, per-posting layers, correction-event policy, and Cube/TBDS shape changes remain unselected.

