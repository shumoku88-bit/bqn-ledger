# Daily Capacity Characterization Amendment

Status: current contract companion
Owner: report / ledger policy / envelope
Canonical: yes; supplements `DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md` for the two carrier states exposed by synthetic characterization
Exit: merge these carrier fields into a future reviewed replacement of the base contract, then retire this companion

Implementation state: test-only characterization selected; `src_next` runtime remains unchanged and unselected.

## Purpose

Synthetic characterization exposed two states that the base contract named in diagnostics but could not represent in its original input carriers:

```text
horizon_unavailable
reservation_provenance_ambiguous
```

The following minimal fields make those states explicit without choosing config keys, source metadata, or a runtime adapter.

## 1. Horizon evidence state

The first-consumer horizon carrier is amended to:

```text
{
  state
  kind
  start
  end_exclusive
  source_ref
}
```

Allowed values:

```text
state = resolved
      | unavailable
      | error
```

Meaning:

- `resolved`: `kind`, `start`, `end_exclusive`, and `source_ref` may be validated for calculation;
- `unavailable`: the caller has explicit evidence that no usable horizon was resolved, producing `state=unavailable` with `horizon_unavailable`;
- `error`: supplied horizon evidence is malformed or contradictory, producing `state=error` with `horizon_invalid`.

A missing or unreadable cycle must not be encoded as plausible dates.

## 2. Reservation provenance state

Each obligation evidence row is amended to carry:

```text
reservation_state
reservation_ref
excluded_from_asset_basis
```

Allowed values:

```text
reservation_state = none
                  | proven
                  | ambiguous
```

### `none`

```text
excluded_from_asset_basis = 0
reservation_ref = empty
```

No amount is proven to be outside the selected asset basis. The full admitted obligation remains deductible.

### `proven`

```text
0 < excluded_from_asset_basis <= obligation amount
reservation_ref = non-empty unique allocation evidence identity
```

Only the proven amount is removed from `obligation_deduction`.

`reservation_ref` identifies the exact allocation/linkage evidence used for this exact obligation amount. It is not merely an envelope or pool name. Reusing the same positive reservation allocation identity for multiple admitted obligations is `duplicate_reservation_linkage`.

### `ambiguous`

The upstream adapter has evidence of a possible reservation relationship but cannot prove whether, or how much, is already outside the selected asset basis.

```text
state = unavailable
code = reservation_provenance_ambiguous
calculation = empty
```

The builder does not guess an excluded amount.

## 3. Exact-once invariant retained

The amendment does not change the selected arithmetic:

```text
obligation_deduction
  = gross_admitted_obligations
    - already_excluded_from_asset_basis

capacity_balance
  = eligible_assets
    - obligation_deduction
```

It only makes the evidence state required to authorize `already_excluded_from_asset_basis` representable and testable.

## 4. Characterization owner

Current test-only executable evidence:

- `tests/daily_capacity_contract_reference.bqn`;
- `tests/test_daily_capacity_contract_characterization.bqn`.

The reference evaluator is deliberately outside `src_next`. It is not a production implementation and must not be imported by report, editor, JSON, or source-writing paths.

## 5. Non-goals

- no `src_next` Daily Capacity builder;
- no config or account metadata key;
- no plan/source-schema change;
- no report, ViewModel, JSON, CLI, or UI output;
- no `POLICY_RISK_STYLE` migration;
- no private or production-data access;
- no generalized reservation ledger or mixed-basis proof system.
