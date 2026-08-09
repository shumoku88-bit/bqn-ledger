# Actual fact sufficiency map

Status: canonical evidence map through Phase 3H
Canonical schema: `docs/LEDGER_FACT_SCHEMA.md`
Current report inventory: `docs/REPORT_CONSTRUCTION_INVENTORY.md`

## Conclusion

Canonical Actual Transaction/Posting Facts contain the successful admitted evidence needed by all current Actual consumers. No report-named field is required in the ledger schema.

Remaining gaps are capabilities or other source families, not missing Actual money facts:

- rejected-source diagnostics stay on `snapshot.diagnostics`, outside successful fact columns;
- cycle and observation coordinates are explicit capability inputs;
- strict Plan/Budget companions are independently admitted and projected through the same Fact schema;
- Source table/index is present now that incomeAnchor and completion are real cross-source consumers;
- remaining report grouping, selection, and presentation views are derived capabilities rather than Fact columns.

## Canonical evidence available

### Transaction Facts

- snapshot-local index and durable/physical transaction identity;
- strict date text and ordinal;
- source line range and source order;
- status marker and description;
- generic admitted metadata plus named relationship IDs;
- Layer/Domain indices and exact calculation scale.

### Posting Facts

- stable posting ID and Transaction join;
- transaction-local posting order;
- date, Account, Layer, and Domain indices;
- exact normalized coefficient/scale and debit/credit side;
- original amount text/coefficient/scale and posting source line.

### Side tables

- explicit one-row Source identity and aligned `source_index` provenance;
- explicit Domain declarations;
- strict Account metadata, including zero-posting accounts;
- admitted Layers;
- aggregate account/Journal/projection diagnostics at snapshot boundary.

## Report capability map

| section | Actual requirement | canonical owner | non-Actual/additional input |
|---|---|---|---|
| `snapshot` | closing account balances, latest date, totals, readiness counts | Posting facts + Account/Domain + Period/Group | cycle, Plan totals, presentation policy |
| `issues` | none | — | `issues.tsv` |
| `ytd` | year interval, account/category movements | Posting date/account/layer/domain/coefficient | explicit year/observation |
| `balances` | cumulative selected-domain account balances | Posting facts + Account table | selected domain and presentation policy |
| `cycle` | income-event dates and in-cycle Actual totals | Transaction date + income-account Posting selection | cycle definition and Plan evidence |
| `trial-balance` | opening/debit/credit/closing by account | Posting date/account/layer/domain/side/coefficient | explicit period/layer/domain |
| `envelopes` | Actual expense movements and liquid balances | Posting facts + Account metadata | Budget and Plan facts, household policy |
| `planned` | Actual completion relationships and amounts | Transaction `plan_id`, date, Posting sides/amounts | Plan facts and observation |
| `recent` | source-ordered transaction descriptions and posting lanes | Transaction facts joined to ordered Postings | display limit |
| `check` | admitted/rejected counts and metadata readiness | fact counts + snapshot diagnostics | Plan/Budget/config diagnostics |
| `outlook` | cumulative Actual snapshot and admitted income anchors | Posting facts + Transaction identity/date | Plan, Envelope, cycle, observation |
| `daily-trend` | row-date Actual replay and income coordinates | Posting date/account/layer/domain/coefficient | Plan reserve facts and row observation |
| `daily-flow` | date × active non-Budget Accounts | Posting facts + admitted Account order/roles | cycle/date policy |
| `actual-comparison` | two explicit windows, account lanes, source-row counts | Posting date/account/side/coefficient/source line | observation and baseline policy |
| `debug` | source balance, identity, zero-sum, provenance | all fact/side-table columns + diagnostics | diagnostic formatting only |

## Editor and operational reader map

| consumer | current need | fact derivation |
|---|---|---|
| Journal list | date, description, credit/debit account lists, debit amount, source order | Transaction index/date/description joined to Posting side/account/coefficient |
| Journal reverse | exact selected transaction, identity, layer, inverse postings | Transaction ID/layer plus ordered Posting source coefficient/scale/account |
| Journal validate/source check | complete no-partial admission | canonical snapshot/admission state and diagnostics |
| Plan finish/list/add/edit/sync | completed Plan IDs, date, amount, from/to lanes | Transaction `plan_id` plus Posting side/account/exact amount |
| cycle resolver | latest date and income-credit dates | Transaction date plus income-account credit Posting selection |
| cache/UI | rendered section output only | no direct fact access |

## Required narrow capabilities

These are consumers over facts, not additions to the fact schema:

1. explicit Posting selection by date/domain/layer/account/side masks (implemented in bounded consumers rather than a textual DSL);
2. transaction-to-posting join by `transaction_index` (implemented);
3. exact amount formatting from coefficient/scale (implemented);
4. source-ordered transaction list rows (implemented);
5. completion Join from explicit `plan_id`, exact debit/credit lanes, and source-qualified contributors (implemented);
6. income-event date selection and mode-specific cycle resolution (implemented);
7. opening/movement/closing Period view (implemented);
8. exact grouping with contributor Posting indices (implemented).

Implement a capability only with a real migrating consumer. Do not create a universal query record or textual DSL.

## Source identity decision

Every independently admitted fact result has one explicit Source row and aligned Transaction/Posting `source_index`. Cross-source consumers retain `{source, transaction_id}` or `{source, posting_id}` references through `src/accounting/fact_reference.bqn`; snapshot-local indices from different sources are never merged.

## Migration progress from this evidence

Completed destination capabilities now include strict Actual/Plan/Budget Facts, Account periods, date/month category grouping and Pivot, Trial Balance and Daily Flow Matrix sections, pure cycle resolution, and durable Plan completion Join. Legacy base-oriented completion remains only with current runtime callers until section cutover.

The current report remains production until each consumer and its output contract move atomically.
