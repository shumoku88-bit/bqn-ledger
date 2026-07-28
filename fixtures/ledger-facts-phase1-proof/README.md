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

`checks/check-ledger-facts-phase1-proof-fixture.sh` fixes current observable behavior beside destination proofs. Planned, Balances, Recent, and Current-cycle Accounts retain their bounded questions. Monthly Accounts proves January movement and an explicit zero February across all eight Accounts. Destination compact keys remain only `ledger_planned_payment`, `ledger_balance`, and tab-delimited `ledger_recent_journal`; Account Matrix reports are human-only. Canonical tests cover source-qualified provenance and exact cross-axis reconciliation. Synthetic tests cover ILS mixed-scale, USD empty Actual, unavailable cycle, empty Recent, observation mismatch, and conflicting completion evidence.
