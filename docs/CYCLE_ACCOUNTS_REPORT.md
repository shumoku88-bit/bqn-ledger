# Retained Current-cycle Accounts report

Status: Portfolio P4 destination proof

Owners:

- `src/accounting/cycle_account_period.bqn` — resolved-cycle and explicit-observation composition;
- `src/accounting/account_period.bqn` — exact Account-period arithmetic;
- `src/sections/cycle_accounts.bqn` — retained five-column Matrix and human renderer.

## Accounting boundary

Input is canonical `actual.journal` Facts, one explicit currency domain, one already-resolved cycle, and one explicit observation date `O`.

For cycle `C=[S,E)` the observation must satisfy:

```text
S <= O < E
observed_end_exclusive = min(O + 1 day, E)
opening window = Actual Postings before S
movement window = Actual Postings in [S, observed_end_exclusive)
```

An observation-bound calendarMonth or incomeAnchor resolution must carry the same observation. Fixed resolution is definition-only and therefore has no observation to match.

The composition delegates arithmetic to `account_period.bqn`, then qualifies all Posting indices with their source. Cycle boundary Transaction contributors remain separate evidence.

## Matrix

```text
rows    = every admitted Account in selected domain order
columns = opening | debit | credit | movement | closing

movement = debit + credit
closing  = opening + movement
```

Credit remains signed negative. Human labels it `Credit (signed)` and does not absolute-value it.

Cell provenance is:

- opening: Postings before cycle start;
- debit/credit: side-specific observed-period Postings;
- movement: all observed-period Postings;
- closing: opening plus movement Postings.

Totals retain exact zero-sum evidence. `balanced` requires zero opening and closing totals and equal signed debit/credit movement totals; it is not a net-worth interpretation.

## Surface

Portfolio P1 supports human output only. There is no compact or JSON renderer and no flattened per-cell key family.

This report replaces the daily-report question previously spread across Cycle Summary and Trial Balance. The existing Trial Balance destination proof remains useful development evidence but does not become a retained route.

## Failure and empty behavior

- valid empty Actual returns every Account as exact zero with no Posting contributors;
- unavailable cycle remains `unavailable` with its reason;
- rejected cycle, wrong Actual source, unknown domain, invalid/out-of-cycle observation, observation mismatch, or exact overflow returns no numeric Matrix.

## Public proof

- JPY partial cycle through `2026-01-10`;
- JPY full cycle through `2026-01-31`;
- signed debit/credit/movement/closing arithmetic;
- source-qualified Posting contributors;
- ILS mixed scale (`12.30` and `0.05`);
- USD valid empty Actual;
- all eight JPY Accounts in admitted order;
- invalid/out-of-cycle/mismatched observation and unavailable cycle;
- deterministic human golden.

Production routing remains unchanged until atomic cutover.
