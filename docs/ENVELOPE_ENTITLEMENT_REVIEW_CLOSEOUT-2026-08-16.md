# Envelope Entitlement BQN-native review closeout — 2026-08-16

## Status

`src/accounting/envelope_entitlement.bqn` has been re-reviewed against the post-clean-epoch Envelope model after the 2026-08-16 BQN-native re-baseline.

This closeout does not reopen the earlier Accounting phase wholesale. It records the one Phase 1 owner that remained explicitly unchecked after the later native Envelope work.

## Defect found by the review

The previous implementation classified admitted Budget movements into three named cases:

```text
Opening/Unassigned -> Envelope   grant
Envelope           -> Unassigned release
Envelope           -> Envelope   reallocation
```

That list accidentally became execution logic rather than explanatory vocabulary. A fully admitted movement from an Envelope allocation Account back to the explicit Opening coordinate matched no case, so the Envelope-side negative effect disappeared from Entitlement.

The Household coordinate was known; the observation was incomplete.

The native law is simpler than the case list:

```text
Budget source Posting on Envelope coordinate      -> negative Entitlement effect
Budget destination Posting on Envelope coordinate -> positive Entitlement effect
```

Opening and unassigned remain distinct physical source coordinates. Neither is itself an Envelope. Therefore:

- Opening -> Envelope produces the destination positive effect;
- Unassigned -> Envelope produces the destination positive effect;
- Envelope -> Opening produces the source negative effect;
- Envelope -> Unassigned produces the source negative effect;
- Envelope -> Envelope produces source negative then destination positive effects;
- movements with no Envelope endpoint produce no managed Entitlement effect.

This matches the current native Envelope projection used by h-kernel without importing its implementation structure into BQN.

## BQN-native change

The review removed two incidental procedural forms.

### Endpoint coordinate selection

An Account now forms its candidate coordinate vector directly from:

```text
matching Envelope coordinates
  ∾ optional unassigned coordinate
  ∾ optional opening coordinate
```

Exactly one candidate is admitted; zero or multiple candidates retain the existing absent/ambiguous sentinel. The expression uses explicit parentheses around boolean Replicate operands because BQN right-to-left evaluation is part of the readable program shape, not something to hide behind formatting assumptions.

### Movement projection

Envelope effects are now projected from the source/destination Posting pair instead of accumulated through mutable `grant` / `release` / `reallocation` branches.

Unassigned effects use the same boolean projection shape. Source order and Posting order remain visible in the resulting ragged cells.

## Complexity deliberately retained

The rest of Entitlement is not rewritten merely to reduce mutation or nesting.

### Ordered diagnostics

`diagnostics∾↩...` remains because validation order and fail-closed publication are part of the public accounting boundary. Converting these guards to a compact expression would not expose a stronger semantic axis.

### Global historical validation

Historical Entitlement validation deliberately remains distinct from visible statement publication:

```text
all admitted Envelope effects
  -> per-Envelope scale
  -> exact normalization
  -> date order
  -> same-day Group
  -> canonical exact day Sum
  -> chronological exact cumulative Sum
  -> nonnegative prefix law
```

Future evidence may therefore invalidate an historically impossible Entitlement sequence even when that future evidence is outside the current observation cutoff. This is a global admission law, not report-window arithmetic.

`exact_scale.Sum` already validates every prefix addition for exact range. The later primitive prefix scan is used only after exactness has been established, to inspect negativity.

### Visible publication scale

The published observation independently chooses its scale from only visible Envelope and unassigned effects. Future effect scale therefore cannot leak into the visible statement merely because global historical validity examines the complete admitted history.

### Provenance and Group

Effect order, source event identity, source Posting index/id, contributor references, canonical Envelope order, trailing empty Envelope groups, and unassigned contributors remain explicit. No generic Envelope transfer framework is introduced across Entitlement, Consumption, Fulfillment, or Commitment.

## Law added

A focused test covers:

```text
Opening -> Envelope 10
Envelope -> Opening 4
=> Entitlement 6
```

and verifies that an over-release to Opening participates in the same global `envelope_entitlement_negative` law rather than disappearing from the observation.

Existing grant, release, reallocation, observation-horizon, mixed-scale, provenance, historical-nonnegative, same-day-order, and exact-range tests remain unchanged and green.

## Decision

The current owner now has the intended shape:

```text
strict admitted inputs
  -> explicit Household endpoint coordinates
  -> Posting-to-Envelope projection
  -> global historical law
  -> visible exact aggregation and provenance
```

No further rewrite is justified in this review. Remaining mutation protects ordered diagnostics, fail-closed gating, or result publication rather than reconstructing a regular data relation procedurally.

The BQN-native review should now return to the normal Phase 6 cursor:

```text
src_edit/journal_block_add_cmd.bqn
```

## Qualification

PR #784 head `7275ef96006225ef86e85e92f71d07630ab87e3b` passed GitHub Actions #3360 through full `tools/check.sh` and coverage before this closeout note was added. Final PR qualification must remain green after the documentation commit.
