# Ledger-facts Phase 1 proof fixture

Public synthetic fixture for the first canonical Actual fact and Trial Balance proof. It contains no household data.

The fixture deliberately provides all approved strict-source coordinates:

- explicit `DEFAULT_CURRENCY=JPY`;
- explicit account roles and currencies;
- one direct `actual.journal` path;
- explicit Plan/Budget row currency;
- durable Plan identity and matching Actual `plan-id`;
- fixed explicit cycle.

Actual evidence includes:

- three transactions and seven postings;
- one three-posting split transaction;
- stable event IDs;
- one completed Plan relationship;
- exact source lines suitable for provenance checks.

Current semantic baseline:

- actual closing: cash `965`, salary `-1000`, food `30`, transport `5`;
- Trial Balance debit `1035`, credit `-1035`, closing `0`;
- Daily Flow has dynamic `food` and `other` columns;
- Recent preserves the split destination list;
- Planned JSON reports the durable Plan as completed with planned `25` and actual `20`.

`checks/check-ledger-facts-phase1-proof-fixture.sh` fixes these observable facts against the current production report. During Phase 1 it becomes an old/new canonical-fact comparison before the old owner is deleted.
