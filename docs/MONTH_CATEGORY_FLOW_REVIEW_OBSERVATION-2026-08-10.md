# Month Category Flow review observation — 2026-08-10

## Baseline

Review starts from merged `main` `1def1d1a2d942f81fbfd73f7bb5da632d2ea49ef` after Month Account movement closeout PR #618.

This record is observation only. It does not change production BQN, result shape, exact arithmetic, diagnostics, source/writer authority, identity, provenance, report output, UI behavior, or the durable review cursor.

## Retained semantic role

`src/accounting/month_category_flow.bqn` does not reclassify raw Facts or own category policy. It composes the already-reviewed Date Category Flow capability and performs one additional semantic reduction:

```text
canonical Facts + admitted Budget/Household policy + explicit query
→ date_category_flow.Build
→ Date × dynamic Expense Category exact evidence
→ YYYY-MM coordinate per Date row
→ Month × Category sparse Group
```

The Month owner preserves:

- the upstream category axis and category identity;
- the upstream exact scale;
- the original contributor Posting indices carried by Date Category Flow;
- deterministic Month then Category group order;
- exact Month-level summation;
- fail-closed empty publication.

The Month reduction is not removable merely because Date Category Flow already aggregates by date. A Month group can combine multiple independently successful Date groups, so Month-level exact summation remains a distinct operation and failure boundary.

Classification: **KEEP the Date → Month semantic reduction if this capability remains retained**.

## Reachability

Current repository search finds no direct `src/`, `src/sections/`, `src/report/`, or `src/application/` importer of `month_category_flow.bqn`.

Current retained reachability is through:

- `tests/test_accounting_month_category_flow.bqn`;
- `checks/check-ledger-facts.sh`;
- active capability/design documents including `MONTH_CATEGORY_GROUPING.md` and `DATE_CATEGORY_FLOW_CAPABILITY.md`.

Historical and current architecture records explicitly describe Month Category Flow as the distinct consumer of Date × Category evidence and as an extensibility capability.

This creates a cross-cutting question rather than an immediate local deletion decision:

> Should a coherent, tested accounting capability with no current user-facing report route remain in the production inventory for reuse/teaching, or should it move/remove during the repository-wide dead-surface audit?

The TODO already contains a separate repository-wide dead-surface and reachability audit. Deleting or relocating the whole owner here would pre-empt that cross-cutting decision.

Classification: **DEFER whole-owner reachability/retention to the repository-wide dead-surface audit**. Do not infer `unused = delete` inside this local review.

## Current input/output shape

Input is exactly the Date Category Flow query:

```text
Facts
Budget policy
Household policy
domain
layer
start ordinal
end-exclusive ordinal
```

Successful output publishes:

```text
state / query coordinates / scale
months: count, index, label
categories: upstream Date Category Flow category table
expense_groups: sparse Month × Category groups
diagnostics
```

`expense_groups.row_index` addresses the Month table and `expense_groups.column_index` addresses the retained Category table. The Month table therefore carries semantic coordinates that cannot be recovered from sparse numeric row indices alone.

Classification: **KEEP Month labels, Category table, exact scale, and sparse group evidence while the capability is retained**.

## Existing kernel

Current successful dataflow is already narrow:

```text
daily ← date_category_flow.Build query
→ dateMonths ← YYYY-MM of daily Date axis
→ monthLabels ← first-occurrence unique dateMonths
→ map Date-group row indices to Month coordinates
→ sparse_group.Build
→ Month table + sparse groups
```

No second category classification, Account scan, source read, report context, Pivot, or presentation policy is present.

The central algorithm is therefore already composition-oriented. The remaining candidates are local structural plumbing rather than an accounting rewrite.

## Subtraction candidate 1: custom `Unique`

Current code uses mutable append plus repeated membership scans:

```bqn
Unique ← {𝕊 items:
  result ← empty
  {𝕊 item: {𝕊: result∾↩⟨item⟩}⍟(¬∨´0∾item⊸≡¨result) @}¨items
  result
}
```

BQN Deduplicate `⍷` already preserves first-occurrence order. The retained `sparse_group` owner explicitly relies on that law for opaque row-axis cells, and reviewed `date_category_flow` already uses Deduplicate for its sorted Date axis.

`dateMonths` is derived from the sorted Date axis, so first-occurrence Month order is the required ascending calendar order.

Candidate replacement:

```bqn
monthLabels ← ⍷dateMonths
```

Existing focused evidence already contains repeated January and February dates, so the two-Month result exercises the relevant deduplication behavior.

Classification: **SUBTRACT candidate / strong**.

## Subtraction candidate 2: duplicate empty sparse-group authority

Month Category Flow locally defines the complete sparse Group result shape:

```bqn
EmptyGroups ← {𝕊:
  {count⇐0,index⇐empty,row_index⇐empty,column_index⇐empty,coefficient⇐empty,contributors⇐empty}
}
```

That namespace is owned already by `src/accounting/sparse_group.bqn`.

The sparse Group focused laws prove that public `sparse.Build` accepts empty evidence, empty row axes, and zero columns and publishes canonical empty groups successfully. Therefore the Month owner should not need to maintain a second literal copy of the Group result shape.

A possible authority-preserving form is to obtain canonical empty groups through the existing `sparse.Build` owner rather than re-declaring its fields locally. The exact final spelling should be chosen together with the failure-path cleanup rather than introducing a helper merely to hide the duplication.

Classification: **SUBTRACT candidate / owner authority duplication**.

## Subtraction candidate 3: placeholder/reset failure staging

Current Build starts by constructing mutable placeholders:

```text
empty Month table
empty Group table
categories = daily.categories
scale = daily.scale
```

It mutates them on success, then performs a final diagnostic-dependent reset back to empty values.

This resembles the pre-review Date Category Flow structure that was later replaced by a named failure result plus a bounded successful kernel.

The Month owner has only two genuine stages:

```text
Date Category Flow succeeds
→ Month Group succeeds
→ publish success
```

and two failure sources:

```text
upstream Date Category Flow diagnostics
Month sparse Group diagnostics, including Month-level exact sum failure
```

A private failure-result constructor and shallow guarded success path should be able to express that dependency directly while preserving the diagnostic owners themselves.

Classification: **RESTRUCTURE / SUBTRACT candidate**, conditional on focused failure evidence.

## Protected Month-level failure boundary

The Month `sparse.Build` call is not redundant validation noise.

Even when every Date × Category cell is individually exact, multiple Date coefficients for the same Month × Category coordinate can exceed the exact range when summed at the Month level. Therefore the Month Group operation and its `group_sum_failed` diagnostic remain semantically meaningful.

The current Month focused test covers successful Actual/Plan rollup and upstream rejection, but does not explicitly characterize a case where Date Category Flow succeeds and the Month regroup alone fails exact summation.

Before changing failure staging, add a focused law that demonstrates:

```text
Date Category Flow = ok
Month Category Flow = error because Month sparse Group sum exceeds exact range
→ Month/categories/groups/scale remain fail-closed empty
→ sparse Group diagnostic is preserved
```

Classification: **LAW FIRST before failure-path refactor**.

## Empty semantic tables

`EmptyMonths` is local Month-result vocabulary and remains justified.

`EmptyCategories` duplicates the upstream category table shape, but unlike sparse Groups there is no current exported canonical empty Category constructor. Exporting a generic/category helper only to shorten this owner would increase API/abstraction surface.

Classification: **KEEP local `EmptyCategories` for now** unless a later shared result-owner review proves a better authority boundary.

## Final observation classification

KEEP while retained:

- Date Category Flow as the source capability;
- distinct Date → Month semantic reduction;
- Month-level exact sparse Group;
- category order and identity from upstream policy;
- contributor order/alignment;
- Month coordinate table;
- exact shared scale;
- fail-closed result semantics;
- upstream and sparse-Group diagnostic ownership.

SUBTRACT / RESTRUCTURE candidates:

- custom mutable `Unique` in favor of Deduplicate `⍷`;
- local literal `EmptyGroups` authority in favor of the sparse Group owner;
- placeholder-success-reset control flow in favor of a shallow failure/success boundary.

DEFER:

- whole-owner deletion/relocation because current production reachability is tests/checks/docs rather than a user-facing route; decide this under the scheduled repository-wide dead-surface audit.

## Recommended next slice

Do not change production first.

1. Add one focused Month-stage exact-overflow characterization proving upstream Date flow can succeed while Month regroup fails closed.
2. With that law in place, simplify `Unique`, empty Group ownership, and failure staging as one coherent Month-rollup cleanup if the resulting diff has one clear reason-to-change.
3. Run focused Month Category, Date Category, Sparse Group, full `tools/check.sh`, and coverage.
4. Reread merged main before deciding whether the local owner review is complete or whether another result-surface question remains.

Keep the durable TODO cursor on `src/accounting/month_category_flow.bqn` until those decisions are merged and reread.
