# Selected-domain Account period capability

Status: Phase 3A public proof
Owner: `src/accounting/account_period.bqn`
Exact arithmetic owner: `src/ledger/exact_scale.bqn`

## Boundary

`account_period.Build ⟨facts,domain,layer,startOrdinal,endExclusiveOrdinal⟩` accepts one successful canonical fact result and explicit query coordinates. It does not accept a source path, report context, cycle source rows, Cube, TBDS, section name, formatter, or clock.

The caller separately admits and resolves source definitions. The public proof converts the already-admitted fixed cycle's date text to ordinals before calling this capability. This keeps period source parsing, period resolution, accounting state, and presentation as separate boundaries.

## Result

The result contains:

- selected domain, layer, period ordinals, and one exact calculation scale;
- Account rows in canonical Account-table order, including zero-activity accounts;
- opening, debit movement, credit movement, net movement, and closing coefficients;
- contributor Posting Fact indices for opening, debit, credit, and all period movement;
- exact totals and a zero-sum/balanced flag;
- fail-closed diagnostics and no Account rows on error.

Amounts remain signed integer coefficient plus result scale. The capability does not choose currency display precision or format text.

## Semantics

For each selected-domain Account:

```text
opening  = sum(postings before period start)
debit    = sum(debit postings in [start, end))
credit   = sum(credit postings in [start, end))
movement = debit + credit
closing  = opening + movement
```

Only postings in the selected layer participate. Account membership comes from explicit Account currency, never account-name prefixes.

`exact_scale.bqn` normalizes admitted signed coefficients to the maximum selected posting scale by constructing and re-admitting the exact integer text. Checked addition fails if the runtime cannot preserve an addition exactly. Different domains are never normalized or added together.

## Public proof

`tests/test_accounting_account_period.bqn` proves the strict public fixture without importing the current report engine:

- eight JPY Accounts in canonical order;
- full-period debit `1035`, credit `-1035`, closing `0`;
- cash `965`, income `-1000`, food `30`, transport `5`;
- a later period with opening cash `980`, opening income `-1000`, opening food `20`, and period movement `15/-15`;
- exact contributor Posting Fact indices;
- signed scale normalization and exact-range rejection;
- unknown domain/layer and invalid period rejection.

This is an accounting capability, not a Trial Balance section implementation. Current formatting and runtime routing remain unchanged until the later report cutover slice.
