# Ledger-facts public proof fixture

Public synthetic fixture for canonical Actual, strict Plan/Budget companion facts, and report parity. It contains no household data. The historical directory name is retained to keep fixture paths stable.

The fixture deliberately provides all approved strict-source coordinates:

- explicit `DEFAULT_CURRENCY=JPY`;
- explicit account roles and currencies;
- one direct `actual.journal` path;
- explicit Plan/Budget row currency;
- durable Plan identity and matching Actual `plan-id`;
- fixed explicit cycle.

Canonical evidence includes:

- three transactions and seven postings;
- one three-posting split transaction;
- stable event IDs;
- one completed Plan relationship;
- one strict Plan transaction and two strict Budget transactions;
- explicit row currency and durable Plan identity;
- exact source lines suitable for provenance checks.

Current semantic baseline:

- actual closing: cash `965`, salary `-1000`, food `30`, transport `5`;
- Trial Balance debit `1035`, credit `-1035`, closing `0`;
- Daily Flow has dynamic `food` and `other` columns;
- Recent preserves the split destination list;
- Planned JSON reports the durable Plan as completed with planned `25` and actual `20`.

`checks/check-ledger-facts-phase1-proof-fixture.sh` fixes observable report behavior and normalized-byte equality with the destination Trial Balance human body. Canonical tests prove aligned facts, strict source/policy/period definitions, Account-period state, date/category flow, January category rollup, exact sparse Group/Pivot, contributor Posting indices, and deterministic destination Trial Balance human/compact goldens. The two-month extensibility case is synthetic inside `tests/test_accounting_month_category_flow.bqn`.
