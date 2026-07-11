# Fintech F1 Multi-time Transaction Semantics — Fit Review

Status: complete
Decision: adopt-later
Date: 2026-07-11
Reviewer: AI (pit)
Selection PR: #178

## 1. Scope

Read-only investigation of current `main` to determine whether F1 "Multi-time Transaction Semantics" should be `adopt-now`, `adopt-later`, `observe`, or `reject`.

The question is not whether multi-time metadata is conceptually useful, but whether the current bqn-ledger has a concrete gap that requires it.

Investigated: source TSV schema, docs, implementation, fixtures, checks, and all report consumers.

Did NOT change: runtime, source TSV, metadata schema, fixtures, checks, or any docs other than the three files in this PR.

## 2. Current source/date contract

### journal first column: `date`

`date` is the **economic occurrence date** — the date when the economic event happened or is expected to happen. This meaning is explicitly documented in `docs/TIME_AS_AXIS.md` and consistently consumed throughout the pipeline:

| Stage | How `date` is used |
|---|---|
| Input UI / editor | User provides economic event date |
| `loader.bqn` | Extracts column 0 as date string |
| `projection.bqn` | Date becomes the posting's temporal coordinate |
| `context.bqn` | Postings filtered/grouped by date; `as_of` resolved separately |
| `cube.bqn` | Day axis = `date` |
| `tbds.bqn` | Period membership = `date ∈ [start, end_exclusive)` |
| All report sections | Single temporal coordinate for period selection |

Other time concepts are explicitly separated:

- `as_of` = observation point (what data is visible)
- `system_today` = OS clock snapshot
- `generated_at` = report production timestamp
- `data_cutoff` = archive boundary

`docs/TIME_AS_AXIS.md` explicitly states the model is single-coordinate: "date is the only coordinate that affects Cube day assignment, TBDS period membership, and report period selection."

## 3. Current plan/date contract

### plan first column: `date`

Plan `date` means the **expected economic event date** — when the planned event is expected to occur. This is consistent with journal `date` semantics.

When a plan entry is finished via `plan finish`:

- The journal entry gets the **actual date** (defaults to today, user can override)
- `plan_id` links the journal entry back to the original plan entry
- Date difference between plan and actual is accepted — `plan_id` maintains the linkage
- Amount can also differ (planned vs actual)

This means the plan-to-actual time mapping is already handled without multi-time metadata:

```text
plan.tsv:    date=2026-02-27  plan_id=xyz  (expected payment date)
journal.tsv: date=2026-02-28  plan_id=xyz  (actual payment date)
```

The `plan_id` linkage is sufficient. No `occurred_on` or `settled_on` is needed to trace plan → actual.

## 4. Current due_on behavior

`due_on` is an optional metadata key defined in `config/meta_schema.tsv` and documented in `docs/JOURNAL_META.md`.

| Property | Status |
|---|---|
| Defined in meta_schema | Yes |
| Formal consumer | `planned_payments.bqn` (display only) |
| Affects Cube day assignment | No |
| Affects TBDS period membership | No |
| Affects balance calculations | No |
| Causes double-counting | No |
| Editor accepts it | Yes (`plan_add_cmd.bqn`) |
| Account metadata derivation | No — it is per-row metadata, not derived from account |

`due_on` represents "when payment is expected to be made." It is used exclusively for display in the planned payments section. It does not participate in any accounting calculation.

For credit card billing, `due_on` can express "this card payment is due on YYYY-MM-DD" without affecting how the payment itself is dated or calculated.

## 5. Current credit-card/liability representation

The current model represents credit cards using standard double-entry bookkeeping with **two separate journal entries** for the two distinct economic events:

### Event A: Card usage (利用日)

```text
date=2026-01-15  memo=コンビニ  from=expenses:food  to=liabilities:credit-card  amount=350
```

- `date` = the date the purchase was made
- Recognizes the expense on the usage date
- Increases credit card liability

### Event B: Card payment/settlement (引落日)

```text
date=2026-02-27  memo=カード引落  from=liabilities:credit-card  to=assets:bank  amount=8500
```

- `date` = the date money was actually withdrawn from bank
- Decreases credit card liability
- Decreases bank balance

### Key observations

1. **Two events, two dates, two entries.** The current model naturally separates card usage date from settlement date because they are different economic events recorded as different journal entries. No multi-time metadata is needed because each entry already has its own correct `date`.

2. **No double-counting.** Card usage goes to expense + liability. Card payment goes from liability to bank. The expense is counted once (at usage). The cash movement is counted once (at settlement). Standard double-entry prevents double-counting.

3. **Planning support.** Card payment can be planned in `plan.tsv` with `due_on` and `anchor=income:年金`. When the plan is finished, `plan_id` links plan to actual.

4. **No credit-card-specific reports.** No credit-card specific report section, consumer, or check exists in current `main`.

5. **No credit-card-specific fixtures.** No fixture specifically tests credit-card billing cycle scenarios, though the sandbox `data/` includes credit card entries.

## 6. Consumer-by-consumer evidence table

| Consumer | Current coordinate/input | Extra time metadata needed now? | Evidence |
|---|---|---|---|
| Cycle Summary | `date` | No | Period membership by date works correctly |
| YTD Summary | `date` | No | Same as cycle summary |
| Expense Breakdown | `date` | No | Filters by date period |
| Recent Journal | `date` | No | Recency by date |
| Planned Payments | `date` + `due_on` | No | `due_on` already provides display info |
| Balances | TBDS closing (`date`) | No | Closing balances correct with single date |
| Snapshot | TBDS closing (`date`) | No | Balance sheet correct |
| Outlook | `date` + plan `date` | No | Projection uses plan date as expected event |
| Daily Trend | `date` | No | Day axis = date, correct |
| Actual Comparison | `date` | No | Aggregate period comparison |
| Envelope Computation | `date` | No | Budget vs actual within period |
| Plan Journal Overlap | `date` + `plan_id` | No | `plan_id` provides strong linkage |
| Plan Finish | plan `date` → journal `date` | No | Actual date replaces plan date naturally |
| Event Lens | `date` | No | Filters by date range |
| Trial Balance | `date` (TBDS) | No | Standard period-based TB |
| Cube | `date` (Day axis) | No | Contract: Day = `date` |
| Readiness Check | `date` | No | Validation by date |
| Household Policy | `date` | No | Period-based policy |
| Reconciliation | N/A (not implemented) | N/A | Future F4 candidate |
| Tax Export | N/A (not implemented) | N/A | Future consideration |
| Credit Card Report | N/A (not implemented) | N/A | Not implemented |

**Zero current consumers require extra time metadata.**

## 7. What current model can represent

The current single-`date` model with separate entries for separate events can represent:

- Card usage expense on the usage date ✓
- Card liability increase on usage date ✓
- Card settlement / bank withdrawal on settlement date ✓
- Card liability decrease on settlement date ✓
- Planned card payments with `due_on` and `anchor` ✓
- Plan-to-actual linkage via `plan_id` ✓
- Balance sheet showing outstanding card liability at any point ✓
- Expense reports showing expenses when they occurred ✓
- Cash flow showing bank movements when they happened ✓

The model correctly separates the two core credit-card time points (usage vs settlement) as two distinct economic events. This is the standard double-entry approach and works without multi-time metadata.

## 8. Concrete gaps found

**None.**

No current consumer produces incorrect results due to the single-`date` model. No current consumer requires `occurred_on`, `booked_on`, `settled_on`, or `paid_on` metadata.

The scenarios where multi-time metadata might become useful are all **future, unimplemented features**:

| Scenario | Status | Would need multi-time? |
|---|---|---|
| Bank statement reconciliation (F4) | Not implemented | Possibly — matching settlement dates to bank CSV |
| Tax export | Not implemented | Possibly — tax date vs payment date distinction |
| Credit card statement view | Not implemented | Possibly — grouping by billing cycle |
| Audit trail with recording timestamps | Not implemented | Possibly — when entries were recorded |

These are speculative benefits for features that do not exist yet. They do not constitute current gaps.

## 9. Input and compatibility costs of extra metadata

If multi-time metadata were adopted now:

| Cost | Description |
|---|---|
| Input burden | Every card transaction or settlement would need extra metadata fields |
| Schema complexity | `meta_schema.tsv` gains new keys that no consumer reads |
| Meaning overlap risk | `occurred_on` vs `date` — which is the "real" date for an entry? |
| Consumer confusion | Reports must decide which date to use for period membership |
| First-five-column safety | Not affected (metadata goes in column 6+), but conceptual complexity increases |
| Editor complexity | `edit-bqn` must accept and validate new metadata keys |
| Fixture/check burden | All fixtures and checks must be updated if the new metadata has behavioral effects |
| Adoption without consumer | Metadata exists but nothing reads it, creating maintenance orphan risk |

The largest cost is **meaning overlap**: if both `date` and `occurred_on` exist on a row, the reader must decide which one is authoritative for period membership. The current model avoids this by having exactly one `date` per entry, which is always the economic occurrence date.

## 10. Decision

**`adopt-later`**

## 11. Rationale

Multi-time transaction semantics are a sound fintech pattern, but bqn-ledger currently has no concrete gap that requires them:

1. **The two-entry model works.** Credit card usage and settlement are naturally two separate economic events with two separate dates. The current double-entry model captures this correctly without needing multi-time metadata on a single entry.

2. **No current consumer needs it.** All 18 report sections and all editor flows work correctly with the single `date` coordinate. `due_on` provides display-only payment date information. `plan_id` provides plan-to-actual linkage.

3. **Costs exceed benefits today.** Adding metadata that no consumer reads creates orphan complexity, input burden, and meaning overlap risk (`date` vs `occurred_on`).

4. **The concept remains valuable for future use.** When reconciliation (F4), tax export, or credit card statement views are implemented, multi-time metadata may become concretely useful. At that point, the specific consumer requirement will determine which time coordinates are needed and how they interact with the existing pipeline.

5. **`docs/TIME_AS_AXIS.md` already provides the extension path.** The document explicitly says: add optional metadata as `key=value` in column 6+, do not change the first five columns, do not overload `date`. This guidance remains correct and does not need to be acted on yet.

## 12. Reopen / next-step condition

Reopen F1 consideration when ANY of the following concrete conditions appears:

- A specific consumer (reconciliation, tax export, credit card view, audit view) is being designed and the designer finds that the two-entry model is insufficient for that consumer's correctness
- A real data scenario is found where the current model produces incorrect results (e.g., wrong expense period, wrong balance, wrong plan-actual linkage)
- Bank statement import (F4) design shows that settlement date matching requires per-row settlement metadata rather than separate entries
- Tax reporting requirements distinguish economic event date from payment date and cannot derive the distinction from existing journal entries

Do NOT reopen just because:
- Multi-time metadata is theoretically useful
- A fintech reference mentions booking/settlement/value dates
- Someone wants to track "when entries were typed in" (that is an audit/editor concern, not a multi-time accounting concern)

## 13. Explicit non-goals

The following are explicitly outside F1's scope and remain non-goals:

- `occurred_on`, `booked_on`, `settled_on`, `paid_on` vocabulary adoption
- Editor-generated `booked_on` timestamps
- Required `settled_on` input on any entry type
- Credit card report implementation
- Changing existing `date` semantics
- Changing first five journal columns
- Phase E, CanonicalEvent, strict event sourcing
- OS clock / `as_of` / `generated_at` responsibility changes
- New general-purpose time abstraction layer
- Reconciliation feature (this is F4, a separate candidate)

## 14. Inspected paths and commands

### Docs inspected

- `docs/TIME_AS_AXIS.md` — canonical time coordination document
- `docs/JOURNAL_META.md` — metadata key definitions
- `docs/REPORT_CONTRACTS.md` — section-level contracts
- `docs/CONVENTIONS.md` — TSV schema and naming
- `docs/POSTING_IR_CONTRACT.md` — Posting IR date handling
- `docs/TBDS_CONTRACT.md` — period membership by date
- `docs/CANONICAL_DAILY_CUBE.md` — Cube Day axis contract
- `docs/ARCHITECTURE.md` — pipeline architecture
- `docs/HEADLESS_KERNEL_EVOLUTION_MAP.md` — Phase E status (not started)
- `docs/FINTECH_ENGINEERING_REVIEW_BACKLOG.md` — F1 candidate description
- `docs/ENGINEERING_ROADMAP.md` — future considerations
- `docs/SAFETY_PROFILE.md` — source TSV protection
- `TODO.md` — current active work

### Source files inspected

- `src_next/loader.bqn` — TSV loading, column extraction
- `src_next/projection.bqn` — Posting IR construction, metadata extraction
- `src_next/context.bqn` — BuildContext, `as_of` resolution
- `src_next/cube.bqn` — Canonical Daily Cube construction
- `src_next/tbds.bqn` — Trial Balance Data Set, period membership
- `src_next/date.bqn` — date utilities
- `src_next/planned_payments.bqn` — `due_on` consumer
- `src_next/snapshot.bqn` — balance sheet
- `src_next/balances.bqn` — account balances
- `src_next/cycle_summary.bqn` — income statement
- `src_next/outlook.bqn` — projection
- `src_next/daily_trend.bqn` — daily trend
- `src_next/actual_comparison.bqn` — period comparison
- `src_next/envelope_computation.bqn` — envelope budget
- `src_next/event_lens.bqn` — event lens
- `src_next/event_lens_format.bqn` — event lens formatter
- `src_next/trial_balance.bqn` — trial balance
- `src_next/plan_journal_overlap.bqn` — overlap detection
- `src_next/report.bqn` — report entry point
- `src_next/summary.bqn` — machine-readable output
- `src_edit/plan_finish_cmd.bqn` — plan completion flow
- `src_edit/plan_add_cmd.bqn` — plan entry creation
- `src_edit/validate.bqn` — input validation

### Data inspected

- `data/accounts.tsv` — sandbox accounts (includes `liabilities:credit-card`)
- `data/journal.tsv` — sandbox journal (includes credit card entries)
- `data/plan.tsv` — sandbox plan (includes card payment plans)
- `config/meta_schema.tsv` — metadata key definitions

### Searches performed

- `due_on` — found in docs, meta_schema, planned_payments, projection, summary, plan_add_cmd, fixtures
- `occurred_on` — found ONLY in FINTECH_ENGINEERING_REVIEW_BACKLOG.md and TODO.md
- `booked_on` — found ONLY in FINTECH_ENGINEERING_REVIEW_BACKLOG.md and TODO.md
- `settled_on` — found ONLY in FINTECH_ENGINEERING_REVIEW_BACKLOG.md and TODO.md
- `paid_on` — found ONLY in FINTECH_ENGINEERING_REVIEW_BACKLOG.md and TODO.md
- `credit` / `card` / `liability` — found in accounts, journal, plan, docs
- `plan_id` — found in plan_finish_cmd, plan_journal_overlap, projection, various docs
- `cashflow` — found in ENGINEERING_ROADMAP only (no implementation)
- `payment` — found in planned_payments and docs
- `引落` / `支払` / `利用日` / `請求` — found in sandbox data and FINTECH_ENGINEERING_REVIEW_BACKLOG.md only
