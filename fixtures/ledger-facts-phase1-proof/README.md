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

`checks/check-ledger-facts-phase1-proof-fixture.sh` fixes current observable behavior beside destination proofs. The retained monetary reports preserve bounded questions and deterministic surfaces. Daily Target proves assets `1000`, once-only deduction `150`, capacity `850`, and target `85`. Strict destination Issues proves durable/source-ordered open rows and optional exact evidence in `issues.destination.tsv`, which current production intentionally does not read. `report_catalog.destination.tsv` fixes the final nine-key order, shape, and supported surfaces without reading household sources. `cycle_baseline.destination.tsv` is the separate admitted fixed baseline used by Cycle Comparison. `daily_target_plan.destination.tsv` and `daily_target_scope.destination.tsv` prove explicit Account/Plan/reservation ownership; `daily_target.application.human.txt` fixes the composed CLI result. `report_all_human.destination.tsv` and `report_all_compact.destination.tsv` are catalog-ordered per-key argv manifests, not universal coordinate records. Synthetic tests cover deficit, reservation conflict/overflow, Plan completion, expense credits/refunds, under-backed funding, cycle comparisons, empty Actual/Issues, unavailable evidence, unknown legacy keys, and unsupported surfaces.
