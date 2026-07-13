# Friend travel source-event → JPY finalization

Status: active semantic plan; writer unselected
Owner: currency / editor / source contract
Canonical: yes; canonical path: `docs/archive/active-plans/FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md`
Exit: archive as completed only after pending storage and the parked atomic-write candidate are separately selected, declined, or superseded.

Runtime status (2026-07-13): the I/O-free `src_next/friend_travel_jpy_finalization.bqn` validator and its unit tests were implemented in PR #210 and independently verified in `docs/archive/audits/FRIEND_TRAVEL_JPY_FINALIZATION_POST_IMPLEMENTATION_VERIFICATION-2026-07-13.md`. Pending source-event storage, safe append, status mutation, durable-index persistence, journal writing, and the synthetic transaction implementation are unselected. `FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md` is retained only as a parked Israel travel candidate 6 proposal.

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

The event is a source fact and must not enter Posting IR, canonical journal expense/cycle totals, envelope consumption, or JPY valuation merely because it exists. No source file, pending-event storage, or safe-append path is currently selected. The parked atomic-write proposal describes one possible `friend_travel_events.tsv` shape for future reconsideration, but it does not establish a current storage contract or generic source-event framework.

## Chosen one-row JPY preview

Let `J` be the human-confirmed final JPY amount. `finalization_date` is a valid date explicitly supplied by the human. It is distinct from the source event's purchase `date`, which remains the observed purchase date and must never be reused as a finalization date. An accepted result contains exactly this one canonical journal preview row:

```tsv
<finalization_date>	<party>: <item_or_category>	<liabilities:friend-JPY>	<expenses:travel-JPY>	<J>	currency=JPY	source_event_id=<source_event_id>	trip_id=<trip_id>
```

`<liabilities:friend-JPY>` and `<expenses:travel-JPY>` are explicit, already-existing account descriptors supplied to the validator. The illustrative names do not authorize account creation, prefix inference, or selection by a UI. The direction is intentional: it increases the existing JPY friend liability and records the sole canonical JPY travel expense.

The row retains `source_event_id` and `trip_id` for provenance. Its memo may be derived from the supplied source-event descriptors, but memo text is not an identity or validation substitute. `original_amount` and `original_currency` never appear as an additional expense amount in this preview.

## Finalization and duplicate contract

`existing_finalization_index` is a supplied index of already-finalized `source_event_id` values. Before producing a preview, the validator requires that the pending event's `source_event_id` has no entry in that index. Any entry rejects the request, including an incomplete or ambiguous historical finalization. The normal path never emits a replacement, second, or repair row for the same identifier.

Durable finalization-index persistence and the atomic status/index/journal writer are currently unselected. The parked candidate 6 proposal records one possible design based on complete validated finalized rows and a recoverable two-file transaction, but it authorizes no commit path. Any future writer must still reject one-sided or conflicting states and must never infer an automatic repair row.

## Validation and fail-closed invariants

The pure validator accepts only:

- a pending source event or typed descriptor satisfying every source-event field contract above;
- an explicitly human-supplied valid `finalization_date`;
- a human-confirmed `J` that is a positive JPY integer;
- an explicit existing JPY friend-liability account descriptor;
- an explicit existing JPY travel-expense account descriptor; and
- the supplied existing-finalization index.

It rejects with zero preview rows if `source_event_id`, `trip_id`, `payer`, `original_amount`, or `original_currency` is missing or invalid; `finalization_date` is missing or invalid; status is not `pending`; `J` is not a positive integer; either selected account is unknown/not-existing or is not JPY; the accounts do not have the required liability/expense roles; or `source_event_id` is already finalized. A missing required top-level, event, or account-descriptor namespace member fails closed as one privacy-safe `request_shape_invalid` diagnostic rather than escaping as an evaluation error. It also rejects any request that would emit an endpoint other than the selected JPY liability and JPY expense accounts.

An accepted result always contains exactly one JPY journal preview row and no foreign-currency journal row, clearing row, or second expense row. An error result contains zero preview rows. This remains the semantic authority for any separately selected future transaction implementation.

## Later repayment

The later repayment is unchanged and remains the existing ordinary journal path:

```text
assets:<JPY account> -> liabilities:<friend JPY>
```

It does not reopen the source event, create a second expense, or require a finalization/clearing row.

## Explicit non-goals

- source-event storage, safe append, status/index mutation, journal writer, production reads/writes, or production trial;
- synthetic transaction implementation, MCP, editor UI, gum/fzf, report, JSON, or Ledger Observatory integration;
- account creation, automatic account selection, or generic source-event storage;
- FX-rate calculation, conversion inference, market valuation, or FX gain/loss;
- clearing accounts, `settlement_clearing`, foreign-currency friend-liability accounts, or two-row settlement;
- foreign-currency canonical postings, foreign expense re-expression, partial finalization, refunds, reversals, or one-to-many allocation;
- strict-source Steps 2–5 or M4.

## Completed first implementation slice: pure validation + one-row JPY preview only

The completed and independently verified slice is an I/O-free BQN pure function and unit tests. Its inputs are the pending source-event descriptor, explicitly human-supplied `finalization_date`, confirmed JPY amount, explicit existing JPY liability and expense account descriptors, and existing-finalization index. Its output is either structured rejection diagnostics with zero preview rows or an accepted result with exactly one JPY journal preview. It performs no TSV reads, writes, environment reads, report changes, editor/UI dispatch, account creation, or status/index mutation.

Required characterization cases include: accepted pending event; each missing/invalid source-event identity and observed-amount/currency field; missing/invalid `finalization_date`; non-`friend` payer; non-pending status; non-positive/non-integer JPY amount; unknown/non-JPY/wrong-role liability or expense account; pre-existing finalization; wrong row direction; any foreign or clearing endpoint; accepted output exactly one row; and every rejection output zero rows.

The verification record classifies every required pure-preview claim as `verified` and closes that finite slice.

## Parked candidate 6: return-home atomic finalization writer

[FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md](FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md) preserves the PR #213 recovery proposal as reference material. Neither its synthetic transaction core nor its proposed storage, status mutation, durable index, journal append, manifest, backup, rollback, recovery, or retry behavior is active work.

Under the Israel travel daily-capture order, pending source-event storage and safe append may be considered before return-home finalization. Candidate 6 may be reselected only in a separate future PR, for example after Israel candidates 1–3 are complete or when return-home finalization is concretely needed. Parking it does not alter the verified pure-preview contract.

## Rejected alternative

The former design that recorded foreign-currency friend liability/expense journal rows and moved them through `clearing:*` into a JPY friend liability using two settlement rows is rejected for this consumer. Its historical/rejected note is [FRIEND_FOREIGN_LIABILITY_JPY_SETTLEMENT_PLAN-2026-07-13.md](FRIEND_FOREIGN_LIABILITY_JPY_SETTLEMENT_PLAN-2026-07-13.md). It authorizes no accounts, role/schema changes, preview, or writer work.

## Dependencies and routing

- The broader travel semantic rails remain in [TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md](TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md).
- The parked candidate 6 proposal for possible future atomicity, storage, recovery ownership, stale checks, backup, retry, and write evidence is [FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md](FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md); it is not implementation authority.
- Current mixed-ledger history and strict-source routing remain in [CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md](CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md), [STRICT_PRODUCTION_SOURCE_CURRENCY_ENFORCEMENT_DECISION-2026-07-13.md](STRICT_PRODUCTION_SOURCE_CURRENCY_ENFORCEMENT_DECISION-2026-07-13.md), and `TODO.md`.
- This plan does not select pending source-event storage, safe append, the synthetic transaction core, atomic finalization writing, strict-source Steps 2–5, M4, Ledger Observatory runtime work, or production finalization writes.
