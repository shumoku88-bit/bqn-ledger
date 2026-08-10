# Month Category Flow review closeout — 2026-08-11

## Baseline

Final reread is against merged `main` `7f08031a1cd51e20dce7f63e496289dca9156b88` after PR #622.

The review sequence was:

- PR #619: architecture observation and reachability classification;
- PR #620: focused law proving Date Category Flow can succeed while Month regroup alone fails exact summation;
- PR #621: subtract custom `Unique`, duplicate sparse Group result authority, and placeholder/reset staging;
- PR #622: remove the remaining empty successful-Date diagnostic carry from the Month kernel.

## Final semantic owner

`src/accounting/month_category_flow.bqn` remains a thin calendar-Month reduction over the already-reviewed Date Category Flow capability:

```text
admitted Facts + Budget/Household policy + explicit query
→ date_category_flow.Build
→ Date × Category exact evidence
→ YYYY-MM coordinates
→ Month × Category sparse Group
→ semantic Month table + retained Category table + sparse evidence
```

It does not reclassify Accounts, re-read sources, own period policy, render a report, or sum across unrelated currencies.

## KEEP

- the named Date → Month semantic reduction while the capability remains retained;
- `date_category_flow.Build` as the upstream source of admitted Date × Category evidence;
- first-occurrence Month order derived from the ordered Date axis;
- the upstream Category axis and identity;
- the shared exact scale;
- original Posting contributor evidence;
- Month-level `sparse_group.Build` as a distinct exact-reduction boundary;
- `group_sum_failed` ownership at the Month regroup operation;
- fail-closed publication with empty Month, Category, Group, and scale surfaces on error;
- local `EmptyMonths` and `EmptyCategories` vocabulary rather than exporting a generic helper solely for this owner.

## SUBTRACTED

- custom mutable `Unique` in favor of BQN Deduplicate `⍷`;
- local literal duplication of the sparse Group public shape;
- placeholder → mutate → diagnostic-reset control flow;
- successful upstream `daily.diagnostics` forwarding after `daily.state = "ok"` has already established that vector is empty.

The final successful kernel now exposes the transformation directly:

```text
Date labels
→ YYYY-MM labels
→ ⍷ Month axis
→ Date-group row coordinates mapped to Month coordinates
→ sparse Group
→ success or fail-closed result
```

## Protected exactness law

PR #620 proves the Month regroup is not redundant plumbing. Thirty-one independently exact Date × food cells can all pass Date Category Flow while their January regroup exceeds the exact integer range. The Month owner must therefore retain its own checked Group operation and propagate `group_sum_failed` without publishing partial semantic tables.

This law remains green after the structural cleanup.

## Reachability decision

Current user-facing production routes do not directly import Month Category Flow. Retained reachability is through focused qualification/checks and capability/design documentation.

That fact does not make the local semantic owner incorrect. Whether a coherent, tested extensibility/teaching capability with no current report route belongs in the final production inventory is a repository-wide reachability policy question.

**DEFER whole-owner retention/removal/relocation to the scheduled repository-wide dead-surface and reachability audit.** Do not reopen the local algorithm review merely because the current user-facing graph does not reach it.

## Final classification

The local owner review is complete on `main` `7f08031a1cd51e20dce7f63e496289dca9156b88`.

No further Month Category Flow-specific subtraction is currently justified. The next normal Phase 1 cursor is:

`src/accounting/plan_completion_join.bqn`
