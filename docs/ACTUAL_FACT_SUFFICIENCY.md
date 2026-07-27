# Actual fact sufficiency map

Status: Phase 1C current evidence
Canonical schema: `docs/LEDGER_FACT_SCHEMA.md`
Current report inventory: `docs/REPORT_CONSTRUCTION_INVENTORY.md`

## Conclusion

Canonical Actual Transaction/Posting Facts contain the successful admitted evidence needed by all current Actual consumers. No report-named field is required in the ledger schema.

Remaining gaps are capabilities or other source families, not missing Actual money facts:

- rejected-source diagnostics stay on `snapshot.diagnostics`, outside successful fact columns;
- cycle and observation coordinates are explicit capability inputs;
- Plan/Budget facts are not admitted yet;
- a logical Source table/index is added when Actual, Plan, and Budget facts share one query surface;
- report grouping, period, completion, transaction-list, and provenance views are derived capabilities.

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
| `daily-flow` | date × dynamic expense category and income | Posting facts + Account budget/group metadata | cycle/date policy |
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

1. `SelectPostings` by explicit date/domain/layer/account/side masks;
2. transaction-to-posting join by `transaction_index`;
3. exact amount formatting from coefficient/scale;
4. source-ordered transaction list rows;
5. completion evidence from explicit `plan_id` and debit/credit lanes;
6. income-event date selection;
7. opening/movement/closing Period view;
8. exact grouping with contributor Posting indices.

Implement a capability only with a real migrating consumer. Do not create a universal query record or textual DSL.

## Source identity decision

Actual currently has one configured Journal source, so posting ID plus source line is sufficient inside the Actual fact set. Combined Actual/Plan/Budget queries will require an explicit logical Source table and `source_index`; add it with companion-source admission rather than embedding filenames in every current Actual row.

## Migration progress from this evidence

Completed in Phase 1C:

1. Journal list/reverse transaction readers;
2. base-oriented completion and income-date evidence;
3. ordinary context/cycle production historical fallback deletion.

Next roadmap boundaries:

4. strict Plan/Budget source admission and the first shared Source table;
5. first Trial Balance Period/Group consumer.

The current human report remains production until each consumer and its output contract move atomically.
