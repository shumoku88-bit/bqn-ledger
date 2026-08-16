# Cross-cutting dead-surface and reachability audit — 2026-08-17

## Scope

This pass follows the production BQN, frontend, writer, and report CLI audits. It concentrates on repository surfaces that can look current merely because a file/function still exists after its topology or caller disappeared.

The classification rule is reachability-first:

```text
no current consumer + retired topology
  -> retire

current consumer + old name
  -> keep as live; naming may be cleaned separately

historical evidence only
  -> keep only when the evidence still explains a current decision
```

An old-looking name is not sufficient evidence for deletion.

## Retired: `tools/src-next-import-graph`

The tool only scanned `.bqn` imports below a hard-coded `src_next` directory.

`src_next/` has already been retired from the production topology, and current developer-tool qualification does not call this import-graph tool. Keeping the script therefore created a runnable diagnostic for a repository subtree that no longer exists.

The tool is removed. Git history remains the appropriate record of the old migration topology.

## Retired: legacy safe-write APIs

The writer/effect audit had already established that active publication callers use caller-owned observation tokens and checked/exclusive primitives.

The following definitions remained in `tools/lib/safe-write.sh` with no active callers:

```text
safe_append
safe_rewrite
safe_create_checked
```

They represented older publication models:

- `safe_append` and `safe_rewrite` took their own snapshot inside the publication helper, after caller validation/preview boundaries;
- `safe_create_checked` used check-then-rename first-file publication and did not close the concurrent first-writer race.

Current code uses:

```text
safe_snapshot_token
safe_create_exclusive_checked
safe_append_checked
safe_replace_line_checked
safe_rewrite_checked
safe_restore_backup_checked
safe_remove_created_checked
```

The old definitions and migration-era usage header are removed. The physical publication owner now exposes only the current checked model.

## Retained: historically named report preview helpers

These files remain live:

```text
tools/command-hub-cache-refresh
tools/command-hub-preview
```

`tools/main-ui.sh` still calls both:

- cache refresh stages/validates the current report preview cache;
- preview reads cache/status files for fzf without starting the report engine.

Their `command-hub` names predate the Calendar-first Household frontend, but reachability is current. They are therefore not dead surfaces.

A future naming-only cleanup may rename them if the churn is worthwhile, but this audit deliberately does not turn old terminology into a deletion heuristic.

## Retained: public editor router

`tools/edit` also remains live. The writer/effect audit already replaced its migration-era comment with its current responsibility:

```text
stronger canonical publication law -> dedicated effect wrapper
other current editor command       -> tools/edit-bqn
```

It is a routing surface, not a compatibility copy of editor semantics.

## Guard

`checks/check-dead-surface-reachability.sh` now requires:

- no `src_next/` directory;
- no `tools/src-next-import-graph`;
- no legacy safe-write function definitions;
- presence of the current checked/exclusive safe-write API set;
- continued reachability of the two live report preview helpers from `main-ui.sh`;
- continued public editor-router reachability.

This check intentionally guards both deletion and retention decisions.

## Result

The obvious executable residue identified during the previous cross-cutting audits has been removed without deleting live adapters simply because their names are historical.

Remaining work is semantic compatibility/history rather than simple reachability:

```text
remaining migration / compatibility residue
checks/tests classification
```

Those require separate decisions about whether current compatibility is intentional law or historical characterization, not another filename purge.

## Next cursor

```text
remaining migration / compatibility residue outside completed canonical Household recovery
```
