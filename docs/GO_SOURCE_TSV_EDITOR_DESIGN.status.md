# GO_SOURCE_TSV_EDITOR_DESIGN status

Status: **historical design draft / decisions digest archived**
Date: 2026-06-22

`docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` is still useful long-form design background, but it should not be used as the current implementation boundary.

## Current implementation boundary

```text
docs/GO_EDITOR_NEXT_PLAN.md
```

## Trust order

1. `docs/GO_EDITOR_NEXT_PLAN.md`
2. `docs/SAFE_WORKFLOW_REDESIGN.md`
3. `docs/GO_SOURCE_TSV_EDITOR_DESIGN.status.md`
4. `docs/archive/completed-plans/GO_SOURCE_TSV_EDITOR_DESIGN_DECISIONS.md`
5. `docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` only as long historical design context

Do not treat stale phase sections in the original design draft as implementation approval.

## Historical decisions digest

Useful preserved design decisions now have a shorter archive digest here:

```text
docs/archive/completed-plans/GO_SOURCE_TSV_EDITOR_DESIGN_DECISIONS.md
```

Use that digest to understand the historical boundary without treating the old draft as current work.

## Current reconciliation snapshot

Current implementation boundary from `docs/GO_EDITOR_NEXT_PLAN.md`:

- read-only plan tools are implemented.
- `journal add` and `budget add` safe append are implemented.
- `plan finish --apply` appends to `journal.tsv` and leaves `plan.tsv` untouched.
- `tools/add-ui.sh` delegates daily append to Go by default.
- extra source TSV writes remain planning-only.
- non-append source-of-truth writes remain planning-only.
- multi-file transactions remain disabled.
- deletion remains disabled.
- TUI/editor expansion remains later.

Still useful historical design decisions preserved by the digest:

- BQN is the canonical scale; Go is the safe glove for touching source TSV.
- Go must not become a second accounting engine.
- Go writes require preview / confirm, atomic write, backup, stale check, and post-write BQN lint.
- `.backup/` lives under the dataset root.
- `plan_id` links plans to later actuals and does not mean the due date has arrived.
- closed plan detection comes from matching `plan_id` in `journal.tsv`.

## Recommended cleanup

Do not delete or rewrite the full original immediately. It is long historical design context.

Later, either:

1. Move the full original document to `docs/archive/completed-plans/GO_SOURCE_TSV_EDITOR_DESIGN.md`, if a safe full-file move is practical; or
2. Replace the original document with a shorter historical stub that points here, to the decisions digest, and to `docs/GO_EDITOR_NEXT_PLAN.md`.

For now, this status file and the decisions digest mark the document as historical without risking loss of the long original text.

## Non-goals

- Do not edit source TSV data.
- Do not change BQN canonical engine responsibilities.
- Do not widen Go editor write scope without explicit approval.
- Do not approve deletion, multi-file writes, or TUI editing through this cleanup.
