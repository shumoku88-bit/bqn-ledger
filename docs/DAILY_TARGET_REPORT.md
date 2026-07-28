# Retained Daily Target report

Status: Portfolio P8 destination proof

Owners:

- `src/accounting/daily_target.bqn` — conservative exact capacity calculation;
- `src/sections/daily_target.bqn` — retained evidence-bearing human/compact Card.

## Boundary

Input is explicit observation `O`, exclusive target `T`, one domain, one owner-resolved `account_balance` asset scope, and one owner-resolved obligation scope. No clock, source loading, Account-name policy, future-income input, or mixed asset basis is accepted.

```text
remaining_days       = T - O
eligible_assets      = sum included exact asset balances
gross_obligations    = sum included open obligations due before T
already_excluded     = sum per-obligation proven reservation exclusions
obligation_deduction = gross_obligations - already_excluded
capacity_balance     = eligible_assets - obligation_deduction
```

When capacity is nonnegative:

```text
state = ok
daily_target = floor(capacity_balance / remaining_days)
daily_shortfall = 0
```

When capacity is negative:

```text
state = deficit
daily_target = 0
daily_shortfall = ceiling((-capacity_balance) / remaining_days)
```

Deficit is a successful evidence-bearing state, not an accounting error.

## Reservation safety

Each positive exclusion requires:

- one included obligation;
- `reservation_state=proven`;
- positive exact excluded amount no greater than that obligation;
- one nonempty reservation reference;
- a reservation reference not reused by another positive exclusion.

Aggregate Envelope/Plan equality is not accepted as reservation provenance. Completed obligations cannot be included. Overdue open obligations remain included; obligations due on or after `T` are outside the half-open horizon and rejected if supplied as included.

All included evidence normalizes to one checked exact scale. The published evidence rows retain normalized amounts and original source-qualified references/contributors. Any normalization or sum overflow publishes no calculation.

## Surface

Portfolio P1 supports human and compact only. Compact keys are the registered `ledger_daily_target_*` family. JSON is unsupported.

The human Statement separately displays asset evidence, per-obligation gross/excluded/deduction/reservation evidence, and calculation coordinates. Future income is absent by construction and cannot increase safe capacity.

## Proof

Public synthetic tests cover funded capacity, proven once-only reservation, deficit/shortfall, empty obligations, overdue open obligation, completed-obligation refusal, over-exclusion refusal, mixed scales, unavailable ownership, outside-horizon obligation, duplicate reservation linkage, invalid date, normalization overflow, source-qualified evidence, funded and deficit renderers, and deterministic human/compact goldens.

Production routing remains unchanged until atomic cutover.
