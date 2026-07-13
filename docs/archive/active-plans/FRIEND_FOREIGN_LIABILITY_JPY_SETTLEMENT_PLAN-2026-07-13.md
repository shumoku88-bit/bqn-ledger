# Friend foreign-liability → JPY-liability settlement

Status: active plan
Owner: currency / editor / source contract
Canonical: yes; canonical path: `docs/archive/active-plans/FRIEND_FOREIGN_LIABILITY_JPY_SETTLEMENT_PLAN-2026-07-13.md`
Exit: archive as completed only after the separately selected pure-preview slice is implemented, tested, and its follow-up write slice is explicitly selected or declined.

## Selected consumer and boundary

This plan selects only this consumer from [TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md](TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md):

1. During travel, record a friend's local-currency advance as an ordinary, single-currency `liability -> expense` journal row.
2. After return, a human confirms both the original foreign amount and the final JPY amount.
3. Close that foreign-currency friend liability and add the confirmed JPY amount to the already-existing JPY friend-liability account.
4. Keep the two single-currency settlement rows linked by one `settlement_id`.
5. Repay the JPY friend liability later through the existing ordinary journal path.

This is neither cash exchange, card lifecycle, trip report, valuation, nor a general multi-currency event model. Original travel expense rows remain facts and are never rewritten.

## Chosen two-row shape

A settlement is exactly two ordinary `journal.tsv` rows with the same date and linkage metadata. Let `FCY` be the foreign currency, `F` the human-confirmed foreign amount, and `J` the human-confirmed JPY amount.

```tsv
# foreign close: reduce the FCY friend liability
<date>	<settlement memo>	clearing:friend-<FCY>	<liabilities:friend-<FCY>>	<F>	currency=<FCY>	settlement_id=<id>	party=<party>	trip_id=<trip>

# JPY assumption: add the confirmed amount to the existing JPY friend liability
<date>	<settlement memo>	<liabilities:friend-JPY>	clearing:friend-JPY	<J>	currency=JPY	settlement_id=<id>	party=<party>	trip_id=<trip>
```

`<liabilities:friend-JPY>` is a selected, already-existing JPY-denominated friend-liability account; the literal shown above is illustrative and must not cause account creation or account-name inference. The preview input must name it explicitly.

The directions are intentional: the FCY row has the normal liability-repayment direction and closes the FCY liability; the JPY row has the normal liability-incurrence direction and increases the JPY liability. Neither row has an `expenses:*` endpoint.

The two amounts are independently confirmed observations. They are not required to satisfy an arithmetic FX-rate rule, and the rows must not be collapsed into a mixed-currency journal row.

## Clearing-account contract

`settlement_clearing` is a prospective account role, not an ordinary liquid asset, cash account, expense, budget account, or FX-gain/loss account. To preserve namespace-role consistency, its future design target is the dedicated `clearing:*` namespace paired with `role=settlement_clearing`, not `assets:clearing:*`. A settlement needs one such account per currency domain:

- `clearing:friend-<FCY>` has account currency `FCY` and appears only in the FCY close row.
- `clearing:friend-JPY` has account currency `JPY` and appears only in the JPY assumption row.

The two accounts form one linked clearing pair through `settlement_id`; they must never be treated as equal-valued balances, netted across currencies, included in liquid-funds/envelope funding, or presented as a market valuation. Their nonzero per-currency movements are the explicit accounting bridge between two confirmed quantities.

Extending the existing account-role/schema contract for `clearing:*`, creating either clearing account, and admitting these rows through a writer are separately selected future work. None is in the pure-preview slice. That slice receives supplied descriptors only; it must not infer the role from an account name, silently create either account, or select the JPY liability by prefix.

## Linkage metadata contract

All three keys are required on both rows and have identical values within the pair.

| Key | Contract |
|---|---|
| `settlement_id` | Ledger-wide immutable identifier for exactly one two-row settlement. It uses a conservative ASCII identifier such as `friend-settle-2026-10-03-alice-01`; it contains no TAB, whitespace, or `=`. A generated candidate is only a suggestion: the validator is authoritative for uniqueness. |
| `party` | Nonempty stable counterparty identifier, not display memo text. It must equal on both rows and match the selected FCY and JPY friend-liability account descriptors. |
| `trip_id` | Nonempty stable identifier for the travel context. It must equal on both rows. It groups this consumer only; it does not authorize trip valuation or a trip report. |

The settlement date is the human-confirmed settlement/assumption date, not a replacement for the date of the original foreign expense. Both rows use the same memo supplied for the settlement; the memo is descriptive only and is not an identity key.

## Safety invariants

### Foreign-liability closure evidence

The typed request must include `foreign_liability_open`, a supplied current-unsettled-liability evidence record containing all of: the selected FCY liability account, its `FCY` currency, its exact positive current unsettled amount, and provenance. Provenance is required structured evidence tying that amount to the source snapshot/reconciliation from which it was derived (including the snapshot identity and the liability-account/currency identity); it is carried into the accepted preview. A human-entered `F` alone is not closure evidence.

The pure validator must require that the selected FCY liability account and `FCY` agree with this evidence and that `F` exactly equals its current unsettled amount at the currency's exact amount representation. An accepted preview carries the evidence and explicitly declares the resulting FCY unsettled amount as zero. Any absent, malformed, contradictory, wrong-account/wrong-currency, or unequal evidence rejects the entire proposal. In particular, an `F` below or above the current unsettled amount fails closed: partial reduction and over-close are outside this consumer.

This remains I/O-free: the preview function does not read a ledger to calculate the amount or provenance. Its caller must supply the evidence value; a later, separately selected read/admission boundary may define how current balance evidence is constructed and freshness-checked.

### Pair admission and duplicate rejection

A valid proposal has exactly the two rows above, one `FCY` row and one JPY row. It is rejected if any required metadata is missing, duplicated within a row, unequal across rows, malformed, or if `FCY=JPY`; either amount is non-positive or invalid for its currency; any account is unknown, has the wrong currency/role/party binding; or either endpoint is an expense or budget account.

The supplied existing-settlement index must contain no occurrence of `settlement_id`. Any occurrence—including a historical one-row partial pair—is a duplicate and rejects the proposal. The normal path never appends a “missing half.” Repairing a legacy partial settlement requires a separately selected recovery design with explicit human evidence.

### All-or-nothing boundary

The first implementation has no I/O and cannot write either row. It accepts explicit account descriptors and an existing-settlement index as values, validates the complete proposal, and returns either one rejected diagnostic result or one two-row preview. It must not emit a one-row preview.

A later, separately selected write slice must preserve the same boundary: validate the complete pair against one source snapshot/fingerprint, stage both lines as one write candidate, and make one safe commit that either makes both lines durable or makes neither line durable. It must backup/stale-check and post-commit verify exactly two rows with the identifier. A failed or ambiguous commit is visible as failure, not retried by appending one row.

### No expense double count

The original FCY `liability -> expense` row is the sole travel-expense observation. Settlement rows are liability/clearing only: they must not use `expenses:*`, carry an expense category, consume an envelope, or be added to expense/cycle totals as a JPY re-expression. The JPY amount represents confirmed JPY liability/funding, not a second food, transport, or other travel expense.

A later JPY repayment remains the existing ordinary row shape:

```text
assets:<JPY funding account> -> <liabilities:friend-JPY>
```

It needs no settlement-clearing row and does not reopen or alter the settled FCY expense.

## Explicit non-goals

- automatic exchange-rate retrieval or inferred conversion;
- market valuation, universal trip conversion, or FX gain/loss accounting;
- cash exchange, card usage/statement matching, partial settlement, refunds, reversals, or one-to-many allocations;
- report/UI work, source migration, fixture changes, or production-source mutation;
- automatic selection of strict-source Steps 2–5 or M4.

## First implementation slice: pure validation + two-row preview only

The only implementation slice this plan authorizes for later selection is an I/O-free BQN pure function and unit tests. Its inputs are a typed settlement request (including `foreign_liability_open`), supplied account descriptors, and supplied existing `settlement_id` occurrences; its output is a structured accepted two-row preview carrying the closure evidence or structured rejection diagnostics. It performs no TSV reads, writes, environment reads, report changes, editor/UI dispatch, or account creation.

Required characterization cases for that later slice include: accepted pair; absent/malformed/contradictory foreign-liability evidence; FCY account/currency mismatch; `F` below or above the evidenced unsettled amount; each malformed/missing/mismatched linkage key; duplicate and pre-existing partial ID; unknown or wrong-currency account; non-JPY domestic liability; `FCY=JPY`; non-positive/malformed amounts; wrong direction; and an expense/budget endpoint.

The write path, balance-evidence read/freshness boundary, existing account-role/schema extension, clearing-account setup, editor command, fixtures, reports, and real-data trial are deliberately **not** part of this slice. Select any write slice only after the pure preview has been reviewed and a new plan defines commit/rollback evidence and recovery ownership.

## Dependencies and routing

- The broader semantic rails and excluded travel consumers remain in [TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md](TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md).
- Current mixed-ledger history and strict-source routing remain in [CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md](CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md), [STRICT_PRODUCTION_SOURCE_CURRENCY_ENFORCEMENT_DECISION-2026-07-13.md](STRICT_PRODUCTION_SOURCE_CURRENCY_ENFORCEMENT_DECISION-2026-07-13.md), and `TODO.md`.
- This plan does not select strict-source Steps 2–5 or M4; those remain independently unselected.
