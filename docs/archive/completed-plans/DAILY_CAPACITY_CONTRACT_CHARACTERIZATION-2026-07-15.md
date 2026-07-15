# Daily Capacity contract characterization — 2026-07-15

Status: completed test-only characterization
Owner: report / ledger policy / envelope
Canonical: no; current contract remains `../../DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md` with companion amendment `../../DAILY_CAPACITY_CHARACTERIZATION_AMENDMENT.md`
Exit: retain as executable-evidence completion record until the contract is replaced

## Purpose

Characterize the selected pre-runtime Daily Capacity boundary with public synthetic evidence before any `src_next` implementation, policy storage, report wiring, or compatibility migration.

Selected boundary:

```text
BuildDailyCapacityFromEvidence
  ⟨observation, horizon, arithmetic_domain, asset_scope, obligation_scope⟩
```

## Delivered executable evidence

The completed slice adds:

- `tests/daily_capacity_contract_reference.bqn`;
- `tests/test_daily_capacity_contract_characterization.bqn`.

The reference evaluator is intentionally test-only. It is not imported by `src_next`, reports, editors, JSON, CLI, or source-writing paths.

The test suite is discovered automatically by the existing `tests/test_*.bqn` loop in `tools/check.sh`.

## Characterized result contract

The synthetic evaluator returns:

```text
state = ok
      | deficit
      | unavailable
      | error
```

Successful arithmetic exposes:

```text
eligible_assets
gross_admitted_obligations
already_excluded_from_asset_basis
obligation_deduction
capacity_balance
remaining_days
daily_capacity
daily_shortfall
```

Selected arithmetic remains:

```text
obligation_deduction
  = gross_admitted_obligations
    - already_excluded_from_asset_basis

capacity_balance
  = eligible_assets
    - obligation_deduction
```

For a nonnegative balance, daily capacity rounds down. For a deficit, spendable daily capacity is zero, the signed balance remains visible, and daily shortfall rounds up.

## Characterized cases

The permanent characterization covers 31 focused cases:

1. resolved-empty asset scope;
2. included and excluded accounts;
3. negative admitted asset balance;
4. account-balance basis without envelopes;
5. pool-remaining basis;
6. mixed-basis rejection;
7. per-obligation deduction evidence;
8. completed obligation excluded by policy;
9. overdue open obligation;
10. obligation exactly on `end_exclusive`;
11. optional purchase excluded by policy;
12. liquid-to-non-liquid transfer excluded as non-obligation;
13. fully externalized obligation;
14. partially externalized obligation;
15. missing reservation provenance;
16. ambiguous reservation provenance;
17. duplicate obligation identity;
18. duplicate reservation linkage;
19. positive daily-capacity rounding;
20. deficit shortfall rounding;
21. exhausted horizon;
22. observation before horizon;
23. observation after horizon;
24. unavailable asset policy;
25. unavailable obligation policy;
26. rejected arithmetic domain;
27. completed obligation incorrectly included;
28. duplicate asset identity;
29. reservation amount greater than obligation;
30. invalid observation date;
31. unchanged current `simple` and `conservative` compatibility outputs.

No production or private fixture is used.

## Contract gaps exposed and closed

Characterization found two diagnostics that the original carrier could name but could not represent explicitly:

```text
horizon_unavailable
reservation_provenance_ambiguous
```

The companion amendment therefore adds:

```text
horizon.state = resolved | unavailable | error
reservation_state = none | proven | ambiguous
```

This is a carrier clarification only. It chooses no config key, source metadata, runtime adapter, or report field.

Characterization also confirmed a BQN-specific implementation rule: enum strings must be compared as whole scalar values. Character membership against a list of strings is not an enum predicate.

## Exact-once reservation result

The tests distinguish three reservation states:

```text
none
  -> full admitted obligation remains deductible

proven
  -> only the exact proven amount already outside the selected asset basis is excluded

ambiguous
  -> calculation unavailable; no guessed amount
```

A positive reservation reference identifies one exact allocation/linkage evidence identity. Reusing it for multiple obligations fails as duplicate linkage.

An envelope name, pool name, or aggregate equality alone remains insufficient evidence.

## Existing runtime compatibility retained

The characterization imports current Outlook only to prove existing behavior remains unchanged:

```text
simple
  -> liq_safe_daily = unavailable/policy

conservative fixture
  -> current numeric liq_safe_daily remains 5240
```

The new test-only reference result is not wired into either path.

## Validation process

A temporary pull-request-only probe workflow and a temporary case-one probe were used to obtain focused BQN failure evidence while developing the tests.

They were removed before completion. They are not part of the permanent repository surface.

The final retained files run under the ordinary repository check suite.

## Boundary retained

This slice does not add or change:

- `src_next` runtime code;
- `POLICY_RISK_STYLE` parsing or fallback;
- current Outlook arithmetic or ViewModel fields;
- config keys;
- account, plan, or source metadata;
- source TSV;
- report, JSON, CLI, UI, or editor output;
- private or production data;
- currency conversion or mixed-domain arithmetic.

## Next eligible finite slice

The smallest next candidate is a pure runtime seam only:

```text
src_next/daily_capacity.bqn
  BuildDailyCapacityFromEvidence input
    -> contract-shaped result
```

A separately selected implementation slice may move the test-only reference behavior into a production pure builder while keeping all adapters absent.

That slice may:

- add the pure module;
- move or reuse the synthetic tests against it;
- preserve deterministic result and diagnostics;
- keep current Outlook and compatibility fields unchanged.

It must not yet:

- resolve owner policy from config or metadata;
- read source files;
- wire Outlook or another report;
- change `simple` or `conservative`;
- add JSON or UI;
- access private data.

This runtime seam remains unselected after the characterization.