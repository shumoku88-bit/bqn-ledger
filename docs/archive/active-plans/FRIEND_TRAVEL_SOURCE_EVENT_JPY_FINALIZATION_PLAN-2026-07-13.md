# Friend travel source-event → JPY finalization

Status: active plan
Owner: currency / editor / source contract
Canonical: yes; canonical path: `docs/archive/active-plans/FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md`
Exit: archive as completed only after the implemented pure-preview slice is reviewed and its follow-up source-event/journal write slice is explicitly selected or declined.

Runtime status (2026-07-13): the I/O-free `src_next/friend_travel_jpy_finalization.bqn` validator and its unit tests were implemented in PR #210 and independently verified in `docs/archive/audits/FRIEND_TRAVEL_JPY_FINALIZATION_POST_IMPLEMENTATION_VERIFICATION-2026-07-13.md`. No source-event storage, status/index mutation, journal writer, editor/UI, fixture, report, or public runtime path is selected or connected. The pure-preview slice is closed; any future atomic write design remains an explicitly unselected candidate.

## Selected consumer and accounting boundary

This plan selects only this consumer from [TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md](TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md):

1. At purchase time, keep a friend's foreign-currency travel purchase as a pending source event, not a canonical journal posting.
2. After return, a human explicitly supplies a valid `finalization_date` and confirms the final JPY amount with the friend.
3. Preview exactly one JPY canonical-journal row from the existing JPY friend-liability account to an existing JPY travel-expense account.
4. Repay that JPY friend liability later through the ordinary journal path.

The source event records the purchase-time fact. The final JPY journal row is the only canonical expense for this consumer. No foreign amount is posted as an expense, and no report may add an original foreign amount and the final JPY amount as two expenses.

## Pending source-event contract

A pending source event, or its typed descriptor supplied to the pure function, contains:

| Field | Contract |
|---|---|
| `date` | Valid purchase date. It remains the observed purchase date and is not a claim about final JPY settlement timing. |
| `party` | Nonempty store/counterparty identifier. |
| `item_or_category` | Nonempty purchased item or category description. It is source-event context, not a second canonical expense posting. |
| `original_amount` | Positive amount in the original currency's admitted exact representation. |
| `original_currency` | Valid nonempty original-currency code. It is an observed fact, not an instruction to convert or post that amount. |
| `payer` | Exactly `friend` for this consumer. |
| `trip_id` | Nonempty stable trip identifier. |
| `source_event_id` | Nonempty immutable source-event identifier, unique in its source-event domain. |
| `status` | Exactly `pending` before finalization. |

For preview metadata safety, `source_event_id` and `trip_id` are nonempty tokens containing no TAB, CR, LF, whitespace, or `=`. `party` and `item_or_category` are nonempty journal-field text and contain no TAB, CR, or LF. In this first slice, `original_currency` is exactly three uppercase ASCII letters; this validates a source-fact token and does not restrict it to the canonical JPY/ILS posting allowlist.

The event is a source fact and must not enter Posting IR, canonical journal expense/cycle totals, envelope consumption, or JPY valuation merely because it exists. This plan does not choose its source file, storage format, or status-transition writer.

## Chosen one-row JPY preview

Let `J` be the human-confirmed final JPY amount. `finalization_date` is a valid date explicitly supplied by the human. It is distinct from the source event's purchase `date`, which remains the observed purchase date and must never be reused as a finalization date. An accepted result contains exactly this one canonical journal preview row:

```tsv
<finalization_date>	<party>: <item_or_category>	<liabilities:friend-JPY>	<expenses:travel-JPY>	<J>	currency=JPY	source_event_id=<source_event_id>	trip_id=<trip_id>
```

`<liabilities:friend-JPY>` and `<expenses:travel-JPY>` are explicit, already-existing account descriptors supplied to the validator. The illustrative names do not authorize account creation, prefix inference, or selection by a UI. The direction is intentional: it increases the existing JPY friend liability and records the sole canonical JPY travel expense.

The row retains `source_event_id` and `trip_id` for provenance. Its memo may be derived from the supplied source-event descriptors, but memo text is not an identity or validation substitute. `original_amount` and `original_currency` never appear as an additional expense amount in this preview.

## Finalization and duplicate contract

`existing_finalization_index` is a supplied index of already-finalized `source_event_id` values. Before producing a preview, the validator requires that the pending event's `source_event_id` has no entry in that index. Any entry rejects the request, including an incomplete or ambiguous historical finalization. The normal path never emits a replacement, second, or repair row for the same identifier.

The accepted result binds the one JPY preview to the pending source event and declares that identifier finalization-reserved for the eventual writer. It is not itself a source-event status write. A future write slice must define the one committed transition from `pending` and the durable finalization-index update together with the journal write; that work is unselected.

## Validation and fail-closed invariants

The pure validator accepts only:

- a pending source event or typed descriptor satisfying every source-event field contract above;
- an explicitly human-supplied valid `finalization_date`;
- a human-confirmed `J` that is a positive JPY integer;
- an explicit existing JPY friend-liability account descriptor;
- an explicit existing JPY travel-expense account descriptor; and
- the supplied existing-finalization index.

It rejects with zero preview rows if `source_event_id`, `trip_id`, `payer`, `original_amount`, or `original_currency` is missing or invalid; `finalization_date` is missing or invalid; status is not `pending`; `J` is not a positive integer; either selected account is unknown/not-existing or is not JPY; the accounts do not have the required liability/expense roles; or `source_event_id` is already finalized. A missing required top-level, event, or account-descriptor namespace member fails closed as one privacy-safe `request_shape_invalid` diagnostic rather than escaping as an evaluation error. It also rejects any request that would emit an endpoint other than the selected JPY liability and JPY expense accounts.

An accepted result always contains exactly one JPY journal preview row and no foreign-currency journal row, clearing row, or second expense row. An error result contains zero preview rows. This is the complete all-or-nothing boundary of the first slice.

## Later repayment

The later repayment is unchanged and remains the existing ordinary journal path:

```text
assets:<JPY account> -> liabilities:<friend JPY>
```

It does not reopen the source event, create a second expense, or require a finalization/clearing row.

## Explicit non-goals

- source TSV reads or writes, source-event storage selection, or status-transition implementation;
- editor/UI, account creation, metadata-schema changes, or writer work;
- FX-rate calculation, conversion inference, market valuation, or FX gain/loss;
- clearing accounts, `settlement_clearing`, foreign-currency friend-liability accounts, or two-row settlement;
- foreign-currency canonical postings, foreign expense re-expression, partial finalization, refunds, reversals, or one-to-many allocation;
- strict-source Steps 2–5 or M4.

## Completed first implementation slice: pure validation + one-row JPY preview only

The completed and independently verified slice is an I/O-free BQN pure function and unit tests. Its inputs are the pending source-event descriptor, explicitly human-supplied `finalization_date`, confirmed JPY amount, explicit existing JPY liability and expense account descriptors, and existing-finalization index. Its output is either structured rejection diagnostics with zero preview rows or an accepted result with exactly one JPY journal preview. It performs no TSV reads, writes, environment reads, report changes, editor/UI dispatch, account creation, or status/index mutation.

Required characterization cases include: accepted pending event; each missing/invalid source-event identity and observed-amount/currency field; missing/invalid `finalization_date`; non-`friend` payer; non-pending status; non-positive/non-integer JPY amount; unknown/non-JPY/wrong-role liability or expense account; pre-existing finalization; wrong row direction; any foreign or clearing endpoint; accepted output exactly one row; and every rejection output zero rows.

The source-event read/write and status-transition boundary, finalization-index persistence, journal writer, metadata-schema admission, fixtures, reports, and real-data trial are deliberately **not** part of this slice. The completed preview does not authorize further runtime work.

## Post-implementation verification and remaining routing

The verification record classifies every required pure-preview claim as `verified` and closes that finite slice. The plan remains active only because its Exit contract also requires the follow-up write slice to be explicitly selected or declined.

A future design for one atomic source-event status transition + durable finalization-index update + journal append is an **unselected candidate**, not active work. It must receive separate authorization and define atomicity, recovery ownership, stale checks, backup, and post-write evidence before implementation. No writer, source-event storage format, strict-source Step 2–5 work, or M4 work is selected automatically.

## Rejected alternative

The former design that recorded foreign-currency friend liability/expense journal rows and moved them through `clearing:*` into a JPY friend liability using two settlement rows is rejected for this consumer. Its historical/rejected note is [FRIEND_FOREIGN_LIABILITY_JPY_SETTLEMENT_PLAN-2026-07-13.md](FRIEND_FOREIGN_LIABILITY_JPY_SETTLEMENT_PLAN-2026-07-13.md). It authorizes no accounts, role/schema changes, preview, or writer work.

## Dependencies and routing

- The broader travel semantic rails remain in [TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md](TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md).
- Current mixed-ledger history and strict-source routing remain in [CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md](CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md), [STRICT_PRODUCTION_SOURCE_CURRENCY_ENFORCEMENT_DECISION-2026-07-13.md](STRICT_PRODUCTION_SOURCE_CURRENCY_ENFORCEMENT_DECISION-2026-07-13.md), and `TODO.md`.
- This plan does not select strict-source Steps 2–5 or M4; those remain independently unselected.
