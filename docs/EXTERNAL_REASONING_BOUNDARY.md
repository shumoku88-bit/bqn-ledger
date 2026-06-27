# External Reasoning Boundary

Status: active design decision / docs-only
Date: 2026-06-22

This document defines where external reasoning systems may help `bqn-ledger` and where they must not become authoritative.

External reasoning systems include LLMs, Datalog/Prolog-style rule experiments, lightweight rule notebooks, or any non-BQN reasoning layer used for checking, explanation, or consultation.

## Core decision

```text
BQN remains the canonical number engine.
External reasoning is not a canonical number generator.
```

Trust order:

```text
1. source TSV files
2. BQN canonical engine / BQN exports
3. external checker observations
4. external explainer text
5. external consultant suggestions
```

External reasoning output must be treated as one of:

```text
observation
explanation
suggestion
proposal
hypothesis
```

It must not be treated as source truth.

## Language policy

Consultation language should stay observational and neutral.

Use:

```text
pace
rhythm
timing
margin
room
review candidate
confirmation candidate
observed change
```

Avoid meaning-heavy labels such as:

```text
bad spending
mistake
must cut
moral judgment
```

If an existing BQN status uses `WARN`, `ERROR`, `SKIPPED`, or `UNAVAILABLE`, the consultant may quote that status as source data. It should not turn report status into lifestyle judgment.

See also: `docs/EXTERNAL_REASONING_NEUTRAL_LANGUAGE_POLICY.md`.

## Non-goals

External reasoning must not:

- write `data/*.tsv`
- edit `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, or `accounts.tsv`
- change `BuildCube` meaning
- replace BQN exports
- calculate canonical balances outside BQN
- silently apply a budget allocation
- mix lifestyle advice into canonical report output
- treat a suggestion as an applied transaction or budget row

Any source TSV change remains a human decision and must go through an approved safe editing path or direct human TSV editing.

## Roles

### checker

Role:

```text
read BQN exports and report observations about differences, missing data, unavailable data, or missing checks
```

Allowed:

- compare BQN exports
- report missing or unavailable data
- report large or changed deltas
- identify possible invariant gaps
- produce `check_result` or `observation`

Forbidden:

- deciding next-cycle budgets
- giving lifestyle advice
- producing canonical balances
- editing source TSV files

### explainer

Role:

```text
explain BQN report/export values, statuses, and differences in human language
```

Allowed:

- explain where a number came from
- explain report statuses
- summarize differences between periods
- translate report sections into readable notes

Forbidden:

- recalculating values as canonical truth
- merging advice into explanation
- changing report contracts
- editing source TSV files

### consultant

Role:

```text
produce human-reviewable proposals for budget allocation, spending review, and next-cycle choices
```

Allowed:

- propose next-cycle envelope allocation
- identify spending review candidates
- observe spending pace patterns
- connect observations to possible budget choices
- output `proposal`, `suggestion`, or `consultation_note`

Forbidden:

- automatically applying `budget_alloc.tsv`
- changing source TSV
- changing BQN canonical output
- claiming the proposal is already applied
- hiding assumptions or unavailable data
- labeling spending as bad or mistaken

### rule notebook

Role:

```text
experimental external reasoning sandbox
```

Allowed:

- test rules against BQN exports
- model observations in Datalog/Prolog/other rule systems
- produce research notes

Forbidden:

- becoming source of truth
- bypassing BQN exports
- writing source TSV
- being required for ordinary canonical report generation

## First practical consultant use cases

The first practical consultant use cases are:

```text
cycle_end_envelope_consultation
spending_review
```

### cycle_end_envelope_consultation

Purpose:

```text
At the end of a cycle, produce a draft next-cycle envelope allocation proposal.
```

Current envelope framing:

```text
Daily / flex / reserve are the active envelopes.
Fixed costs and savings are outside envelope control.
```

Rules:

- proposal is not canonical output
- proposal is not written to `budget_alloc.tsv`
- proposal must include assumptions
- proposal must separate BQN-derived numbers from external interpretation
- proposal must say when data is unavailable or stale
- proposal should use neutral observation language

### spending_review

Purpose:

```text
Identify spending areas and spending rhythms that may be useful to review before deciding the next cycle.
```

Spending review is not only amount ranking. It includes pace and timing patterns.

```text
spending_review = amount_review + unplanned_pace_review + timing_pattern_review + margin_review
```

## Planned vs unplanned actual spending

Important decision:

```text
Spending pace review should focus primarily on actual spending that is not already represented by plan.tsv.
```

Reason:

```text
plan.tsv spending = known / already noticed spending
unplanned actual spending = living rhythm that emerged during the cycle
```

This does not mean unplanned spending is bad. It means unplanned actual spending is a useful pace signal.

### planned spending

Definition:

```text
spending represented in plan.tsv
known events
fixed or expected items
already noticed future/periodic spending
```

Use:

- check whether planned spending happened
- explain expected cash movement
- separate known commitments from living rhythm

Do not mix planned spending into unplanned pace signals.

### unplanned actual spending

Definition:

```text
actual spending present in journal.tsv / BQN actual exports but not represented by plan.tsv
```

Use:

- observe food pace
- observe tobacco pace
- observe variable spending rhythm
- identify weekend increases
- identify post-income front-loading
- identify end-cycle narrow room
- identify short clusters of one-off spending

Unplanned actual spending should be described as:

```text
living rhythm
allocation signal
review candidate
margin signal
```

not automatically as:

```text
bad spending
mistake
must cut
```

## Spending review observation types

### amount_review

Looks at total amounts by category, envelope, account, or report lane.

Useful question:

```text
What was large enough to be useful for review?
```

### unplanned_pace_review

Looks at how quickly unplanned actual spending appears over the cycle.

Useful questions:

```text
How does food spending pace compare with remaining days?
Did tobacco spending pace change around a certain date?
Was variable spending front-loaded after income?
```

### timing_pattern_review

Looks at when spending happens.

Initial pattern names:

```text
weekend_food_increase
post_income_frontload
end_cycle_narrow_room
tobacco_pace_change
single_expense_cluster
```

### margin_review

Looks at available room and remaining-days relation without moral meaning.

Examples:

```text
food envelope room became small
end-cycle remaining room narrowed
tobacco pace changed
one-off spending clustered
some report data was missing or unavailable
```

Margin review should produce review candidates, not judgment.

## Data flow

Preferred flow:

```text
source TSV -> BQN canonical engine/export -> external reasoning -> consultation output -> human decision -> approved edit path if needed
```

The consultant should primarily read BQN exports rather than raw source TSV.

If raw TSV is ever used for a consultation prototype, the output must clearly state:

```text
raw TSV was read directly
this is not canonical output
BQN export confirmation is required before applying decisions
```

## Consultation output contract

A consultation output should include:

```text
consultation_type:
  cycle_end_envelope_consultation | spending_review | margin_note

status:
  draft | needs_human_decision | blocked_by_unavailable_data

uses:
  bqn_export_name
  as_of
  cycle_id_or_period

observations:
  BQN-derived facts and external pattern observations

proposal:
  human-readable suggestion or allocation draft

rationale:
  numbers_from_bqn
  assumptions
  interpretation

data_notes:
  unavailable_data
  stale_data
  uncertain_mapping

do_not_apply_automatically:
  true
```

Required rule:

```text
do_not_apply_automatically must be true for consultant output.
```

## Example: spending review

Output idea:

```text
consultation_type: spending_review
status: draft
observations:
  amount_review:
    - food was one of the larger variable areas
  unplanned_pace_review:
    - unplanned food spending was faster in the first part of the cycle
  timing_pattern_review:
    - weekend_food_increase: possible
    - post_income_frontload: possible
    - tobacco_pace_change: possible around <date range>
  margin_review:
    - end-cycle remaining food room narrowed
proposal:
  - consider weekend-aware food allowance
  - consider early-cycle Daily pace display
  - consider separate observation of tobacco pace
do_not_apply_automatically: true
```

## Open questions

- Which BQN export should supply unplanned actual daily spending?
- How should planned-vs-unplanned matching be represented?
- Is `plan_id` enough for known plan matching, or are category/account/date heuristics needed?
- Should weekend/weekday labels be exported by BQN or added by an outer helper?
- Should tobacco pace be tracked by amount only or by explicit quantity metadata?
- Should consultation output be Markdown first, TSV/JSON later, or both?
- Should the first prototype be manual prompt-only before any tool is added?

## Implementation gate

No implementation is approved by this document.

A future approval should say something like:

```text
Approve docs-only consultation packet for cycle-end envelope consultation.
No new BQN export yet.
No source TSV writes.
No budget_alloc.tsv changes.
Use existing BQN report/export output only.
```

Or, for an export-focused phase:

```text
Approve design of a BQN export for unplanned actual daily spending.
No consultant automation yet.
No source TSV writes.
No budget_alloc.tsv changes.
```
