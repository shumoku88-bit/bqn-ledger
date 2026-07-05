# Config Resolution A4 Completion Decision

Status: A4 completion decision / docs-only / no runtime authorization
Date: 2026-07-05
Parent plan: `CONFIG_RESOLUTION_SEMANTICS_PLAN-2026-07-05.md`
Runtime checkpoint: `CONFIG_EFFECTIVE_RESOLUTION_RUNTIME_CHECKPOINT-2026-07-05.md`
Classification item: A4 Partial `config.tsv` semantics

## Decision

A4 is complete enough for now.

This does not mean every possible config problem is solved.

It means A4 has reached its intended risk-reduction point:

```text
raw config behavior is characterized
typed sparse override has one real runtime proof
ambiguous keys are quarantined
future work can be split by concrete problem
```

No further A4 implementation should continue by momentum.

## Why this is enough

A4 now has evidence for the original problem areas:

```text
file-level replacement semantics        characterized
missing vs explicit empty               characterized
presence-aware raw Lookup               implemented
raw Get compatibility                   preserved
required-key failure behavior           characterized
typed POLICY_BUDGET_STYLE               implemented
typed POLICY_RISK_STYLE                 implemented
POLICY_INCOME_CADENCE ownership         decided as dormant future policy
minimal effective sparse override       implemented for LIFE / RESERVE
raw/effective semantic separation       implemented for first runtime slice
```

The key result is the raw/effective separation:

```text
raw Lookup / Get
  observes what the selected config source physically contains

effective accessors
  may apply approved application meaning
```

That boundary is no longer only a design idea.

It exists in runtime for:

```text
HOUSEHOLD_GROUP_LIFE
HOUSEHOLD_GROUP_RESERVE
```

## What remains unresolved

These are not blockers for closing A4.

They are future independent questions:

```text
duplicate-key runtime contract
global unknown-key policy
UI ownership split
eager repository-default source loading
HOUSEHOLD_GROUP_ORDER redesign
BUDGET_* ownership cleanup
optional-key migration
fixture simplification
```

Do not treat unresolved as unfinished A4 work.

Treat each as a separate future task only if it becomes a current concrete problem.

## Closed scope

A4 closes with these boundaries still in force:

```text
no global merged config table
no generic schema framework
no all-key resolver
no automatic third-key migration
no duplicate-key behavior change
no global unknown-key errors
no UI split
no ORDER redesign
no BUDGET cleanup
no income-cadence runtime work
no live config rewrite
no source TSV mutation
```

## Future reopening rule

A4 itself should not be reopened just because another config idea appears.

Future work must start as a new concrete slice naming:

1. exact problem,
2. exact key or file boundary,
3. current consumer,
4. ownership class,
5. desired missing behavior,
6. desired explicit-empty behavior,
7. compatibility impact,
8. focused tests.

Examples:

```text
duplicate key contract
  -> new independent config validation slice

UI ownership split
  -> new UI/config ownership slice

BUDGET_* cleanup
  -> new legacy-contract-review slice

HOUSEHOLD_GROUP_ORDER redesign
  -> new derived-order design slice
```

## Relationship to TODO.md

`TODO.md` remains the preferred source for choosing current work.

A4 active-plan documents remain useful background, but they no longer imply active implementation.

If future config work becomes important, promote one concrete item into `TODO.md` or a new docs-only decision before touching runtime.

## Final A4 state

```text
A4 status                         complete enough for now
runtime proof                     yes, LIFE / RESERVE
raw/effective boundary             established
broad config framework             not adopted
remaining config questions         split into future independent work
next recommended action            return to current TODO selection
```

## Recommendation

Close A4 here.

Return to current project selection rather than continuing config work by key count.
