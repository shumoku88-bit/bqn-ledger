# Daily Capacity pure runtime seam — 2026-07-15

Status: completed implementation slice
Owner: report / ledger policy / envelope
Canonical: no; current contract: `../../DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`
Exit: retain as the completion record for the unconnected pure runtime seam

## Purpose

Move the established test-only Daily Capacity evaluator into one production-available pure BQN module without selecting policy resolution, source loading, Outlook wiring, output migration, or compatibility migration.

## Delivered boundary

`src_next/daily_capacity.bqn` exports:

```text
BuildDailyCapacityFromEvidence input
  -> {
       state,
       observation,
       horizon,
       arithmetic_domain,
       asset_evidence,
       obligation_evidence,
       calculation,
       diagnostics
     }
```

The function accepts only the five already-resolved in-memory evidence parts:

```text
observation
horizon
arithmetic_domain
asset_scope
obligation_scope
```

It performs no source or config read, system-clock read, environment access, output, process exit, rendering, mutation, policy inference, or currency conversion.

## Characterization retained

`tests/test_src_next_daily_capacity.bqn` targets the production export and retains all 31 public synthetic cases from the test-only characterization, including:

- account and pool asset bases, mixed-basis rejection, and negative admitted assets;
- open, completed, overdue, excluded, and out-of-horizon obligations;
- exact full and partial reservation exclusion, missing or ambiguous provenance, and duplicate linkage;
- `ok`, `deficit`, `unavailable`, and `error` precedence;
- floor/ceiling arithmetic and horizon boundary states;
- unchanged current `simple` and `conservative` Outlook compatibility outputs.

The former `tests/daily_capacity_contract_reference.bqn` was moved rather than retained as a duplicate oracle. Explicit expected values and diagnostic codes in the characterization remain the independent assertions; keeping a second implementation would create drift risk.

## Contract result

No new contract defect or ambiguity was found while moving the characterized behavior. The companion carrier states remain:

```text
horizon.state = resolved | unavailable | error
reservation_state = none | proven | ambiguous
```

For `unavailable` or `error`, calculation remains empty. A negative `capacity_balance` remains signed and produces `state=deficit`, `daily_capacity=0`, and a positive rounded-up `daily_shortfall`.

## Compatibility and boundary

This slice does not import the module from Outlook, report, summary, JSON, CLI, UI, editor, or a source-writing path. It does not change:

- `POLICY_RISK_STYLE` parsing, fallback, or meaning;
- `liq_daily`, `liq_safe_daily`, or their exported fields;
- config keys or source metadata;
- source TSV schemas or data;
- currency-domain policy.

## Next separately selectable candidate

The smallest next candidate is a test-only characterization of one concrete evidence adapter boundary that can construct the five-part input carrier for this pure function while leaving Outlook output unchanged.

That candidate is unselected. It must first name the evidence owner and must not introduce config or metadata, access private data, wire reports, or migrate `simple` / `conservative` merely because this seam exists.
