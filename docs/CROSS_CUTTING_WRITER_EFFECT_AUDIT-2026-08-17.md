# Cross-cutting writer/effect ownership audit — 2026-08-17

## Scope

This audit follows the frontend/action consolidation and traces active publication paths from admitted BQN intent to physical source mutation.

The boundary under review is:

```text
BQN/application observation
  -> semantic candidate or intent
  -> machine protocol
  -> shell snapshot / stale fence
  -> checked publication
  -> mandatory post-write admission
  -> digest-guarded rollback on failure
```

The goal is not to move filesystem effects into BQN. It is to ensure shell owns only bounded publication mechanics and that no active writer bypasses the shared checked primitives.

## Current publication core

`tools/lib/safe-write.sh` is the physical publication owner.

Current active writers use caller-owned observation tokens and checked primitives:

```text
safe_append_checked
safe_replace_line_checked
safe_rewrite_checked
safe_create_exclusive_checked
safe_restore_backup_checked
safe_remove_created_checked
```

The caller captures the source observation before semantic validation / preview. Publication therefore verifies the same observed bytes immediately before mutation rather than taking a new snapshot after the user or BQN work has already happened.

## Shared editor effect owner

`tools/lib/edit-bqn-common.sh` owns shared shell protocol/application mechanics for the `tools/edit-bqn` family:

- checked append;
- checked exact-line replace;
- checked candidate rewrite;
- canonical-surface rewrite application;
- post-write validation dispatch;
- digest-guarded rollback.

Ledger meaning stays in `src_edit/` BQN owners.

After this audit, Issue append and replace follow the same rollback law as Journal/Account publication: a failed mandatory/default post-check restores the exact observed source bytes if the target still equals the bytes this writer published.

## Dedicated canonical writer slices

Some public editor commands deliberately have dedicated shell effect owners rather than going through one generic apply function. They are not compatibility shells; each protects a stronger observation boundary.

### Plan Add — `tools/plan-add`

```text
Plan observation token
-> BQN full candidate admission
-> checked append
-> mandatory Plan admission
-> optional full check
-> digest-guarded rollback
```

### Plan Edit — `tools/plan-edit`

```text
Plan observation token
-> BQN source-coordinate candidate rewrite
-> checked whole-file rewrite
-> mandatory Plan admission
-> optional full check
-> digest-guarded rollback
```

### Plan Finish — `tools/plan-finish`

Plan completion has two-source observation semantics:

```text
Plan observation
+ Actual observation
-> BQN completion intent
-> BQN Actual block candidate
-> recheck both observations
-> checked Actual append
-> native Actual candidate validation
-> completion-link validation
-> Household ledger check
-> Plan still unchanged
-> digest-guarded Actual rollback on failure
```

The separate wrapper therefore protects a real Plan/Actual race fence rather than duplicating a generic writer for convenience.

### Budget movement — `tools/budget-write`

Budget publication observes the canonical Household source set before constructing the candidate. It checks the complete initial observation, publishes through `safe_append_checked`, then verifies non-Budget sources remained unchanged while Budget and Household admission succeed.

That Household-wide fence is a real stronger law and justifies the dedicated effect owner.

### Canonical Journal Surface — `tools/journal-canonical-surface`

BQN owns classification, rewrite semantics, candidate bytes, and semantic equivalence. Shell owns path identity, snapshot, confirmation, checked rewrite, post-check, and rollback.

The current boundary is already explicit and remains unchanged.

### Travel source events

`tools/lib/edit-bqn-travel.sh` uses checked append for existing source-event files and `safe_create_exclusive_checked` for first publication. A failed source validator restores the backup or removes the newly-created file only if its digest is still the writer's published digest.

## Concrete defect 1: first Issue publication race

Before this audit, first creation of `issues.tsv` used `safe_create_checked`.

That helper performed:

```text
check target absent
stage candidate
check target absent
mv candidate -> target
```

A concurrent writer could create the target after the final absence check but before `mv`, allowing the losing candidate to replace concurrent bytes.

Issue first publication now uses `safe_create_exclusive_checked`, matching Travel first-file publication. The final publish uses a same-filesystem hard link and therefore fails if another writer wins creation first.

A regression injects a concurrent creator at the immediate publication seam and requires:

- Issue command fails;
- concurrent bytes remain exact;
- no misleading backup is created.

## Concrete defect 2: failed Issue post-check left published bytes

Issue Add/Close previously differed from the other active writer classes.

For an existing `issues.tsv`, append/replace could publish successfully, fail `issue_validate_cmd.bqn` or the selected post-check, return failure, and leave the new bytes in place.

For first creation, a failed post-check likewise left the newly-created file behind.

The audited law is now consistent:

```text
publication succeeds only if mandatory/default post-check succeeds
```

Failure handling:

- existing Issue append -> restore checked backup;
- existing Issue replace/close -> restore checked backup;
- first Issue create -> remove created file only if its digest still equals the writer's published digest;
- if another process changed the target after publication -> refuse destructive rollback and require recovery.

Regressions force each of those validation failures and require exact pre-write bytes (or absence for first creation) after command failure.

## Public editor router

`tools/edit` remains useful as the stable public editor dispatcher.

Its old comment described dedicated canonical slices as gradual migration away from an older monolithic implementation. That is no longer an accurate architectural description.

The current role is simply routing:

```text
stronger canonical publication law -> dedicated effect owner
other current editor command       -> tools/edit-bqn
```

`tools/edit` owns no candidate meaning or source mutation algorithm.

## Legacy safe-write APIs

`safe-write.sh` still contains older self-snapshotting / non-exclusive helper definitions such as:

```text
safe_append
safe_rewrite
safe_create_checked
```

The writer ownership check requires that **no active tool/check/test calls them**. They therefore are not current writer authority.

Their definitions remain dead-surface residue to classify/remove in the repository-wide dead-surface lane. Keeping that deletion separate avoids rewriting the large physical publication owner in the same PR as the Issue safety fix.

## Repository guard

`checks/check-writer-effect-ownership.sh` now guards:

- exclusive first-file Issue and Travel publication;
- no caller of legacy non-exclusive/self-snapshotting writer APIs;
- shared checked append/replace/rewrite ownership;
- positive first Issue creation;
- concurrent first-create race safety;
- first-create post-check rollback;
- existing Issue append post-check rollback;
- existing Issue replace post-check rollback.

## Decision

Active writer/effect ownership is now coherent:

```text
semantic meaning / candidate
        BQN
         |
         v
checked physical publication
        shell
         |
         v
mandatory observation + guarded rollback
```

The next cross-cutting lane is report/application CLI reachability, while dead legacy safe-write API definitions remain explicitly queued for repository-wide dead-surface cleanup.
