# TODO

Status: active backlog / work router
Owner: workflow
Canonical: yes
Exit: revise when a finite slice is selected, completed, declined, or rerouted

このファイルは次の4種類だけを置く場所です。

1. **Active work** — 現在進行中または次に終わらせる有限作業
2. **Next candidates** — まだ着手を決めていない小さな候補
3. **Continuous maintenance** — 終了させない基礎保守ループ
4. **Hold / later** — 具体的必要が出るまで保留するもの

完了済みの長い履歴は `docs/archive/TODO_HISTORY-*.md` に退避します。

## Current baseline

Last hygiene pass: 2026-07-25

- Native Journal is the only production Actual source selected by `ACTUAL_JOURNAL_FILE`.
- `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv` remain companion/configuration source files.
- Actual TSV runtime, fallback, dual-write, editor, and active-fixture routes are retired.
- The selected report-projection alignment sequence is complete; no next finite report slice is selected.
- The selected Journal parser, Posting IR, read-path, cutover, canonical-surface, and reconstructible-identity cleanup sequence is complete; no next finite Journal slice is selected.
- The unused MCP adapter is retired. Its pre-removal implementation remains recoverable from Git tag `checkpoint-pre-mcp-removal`.
- The Israel 2026 travel funding and settlement ownership characterization is complete.
- JPY→ILS exchange safe append and friend-paid pending safe append already exist.
- Native Journal ordinary Actual writing, selected read-path wiring, and selected balances remain JPY-only; ordinary ILS travel spending is not currently admitted by the runtime route.
- The non-JPY single-currency characterization and test-only admission proof are complete. Public-synthetic ILS and USD witnesses share one registry-driven domain, precision, account-currency, normalization, balance, and structural-trace boundary while production Journal routes remain unchanged.
- The multi-currency Journal container contract and test-only proof are complete. One public-synthetic Journal admits separate JPY and ILS ordinary transactions, a JPY and USD witness proves generality, every transaction retains its own domain and scale, and mixed-domain ordinary transactions fail closed.
- The production complete-source admission boundary is complete. It returns per-transaction domains, scales, normalized posting evidence, account-currency proof, identity, metadata, and source provenance without a Journal-wide money domain or total, but it is not yet wired into Actual loading or Stage 2A.
- The generic projection and valuation foundation remains an active backlog, not implementation authorization.
- Detailed completion history through the previous checkpoint is in `docs/archive/TODO_HISTORY-2026-07-24.md`.

---

## Active work

### Stage 2A currency-proof carrier

Status: selected finite production carrier implementation.

Canonical evidence:

- `src_next/journal_complete_source_admission.bqn`
- `tests/test_journal_complete_source_admission.bqn`
- `src_next/journal_posting_ir_stage2a.bqn`
- `tests/test_journal_posting_ir_adapter_stage2a.bqn`
- `docs/POSTING_IR_CONTRACT.md`
- `docs/archive/active-plans/MULTI_CURRENCY_JOURNAL_CONTAINER_CONTRACT-2026-07-25.md`

Selected implementation boundary:

- add an explicitly named Stage 2A currency-proof carrier that consumes admitted complete-source transactions and resolved account evidence;
- preserve the existing `journal_posting_ir_stage2a.bqn` module and its current 16-field `delta` row contract unchanged;
- emit a separate row shape carrying source identity and provenance, transaction domain, calculation scale, account currency, commodity, source amount text, source coefficient, source scale, and normalized coefficient;
- do not emit an untyped money `delta` from multi-currency evidence and do not present normalized coefficients as one Journal-wide arithmetic vector;
- preserve transaction order and posting order while retaining source start/end lines and posting source lines;
- validate registry-supported domains, transaction/posting domain equality, resolved account-currency equality, normalization consistency, posting identity, and per-transaction normalized balance;
- fail closed for the complete carrier result and return no partially admitted rows when any transaction or posting proof is invalid;
- prove separate JPY and ILS rows from one source plus USD as a second registry-driven witness;
- perform no I/O and remain disconnected from `actual_source`, context, Cube, TBDS, reports, balances, writers, editors, and private data.

This slice must not change Stage 1 admission, the existing Stage 2A adapter, current Posting IR consumers, context composition, a Currency axis, FX, valuation, exchange semantics, metadata admission, or travel routes.

The latest AI working feedback remains evidence only and does not authorize additional work.

---

## Next candidates

### Multi-currency native Journal container continuation

Status: contract, test-only container proof, and production complete-source admission complete / candidate 1 selected / all later continuation slices independently unselected.

Current evidence and contract:

- `docs/archive/audits/NATIVE_JOURNAL_NON_JPY_SINGLE_CURRENCY_ADMISSION_CHARACTERIZATION-2026-07-25.md`
- `src_next/journal_supported_single_currency_admission_for_test.bqn`
- `tests/test_journal_supported_single_currency_admission_proof.bqn`
- `docs/archive/active-plans/MULTI_CURRENCY_JOURNAL_CONTAINER_CONTRACT-2026-07-25.md`
- `src_next/journal_multi_currency_container_admission_for_test.bqn`
- `tests/test_journal_multi_currency_container_admission_proof.bqn`
- `src_next/journal_supported_single_currency_admission.bqn`
- `src_next/journal_complete_source_admission.bqn`
- `tests/test_journal_complete_source_admission.bqn`

Recommended candidate order:

1. **Stage 2A currency-proof carrier decision and implementation** — selected above; retain posting domain, calculation scale, normalized coefficient, source amount evidence, account-currency proof, and provenance without changing current consumers automatically.
2. **Selected-domain context composition** — compose Actual + plan + budget for exactly one selected currency at a time or explicitly separate partitions; do not add a Currency axis automatically.
3. **Native ordinary-add writer widening** — accept one explicit supported transaction currency while preserving existing JPY behavior.
4. **Per-domain consumer and formatting verification** — selected balances and immediate consumers never produce combined multi-currency totals.
5. **Explicit exchange-in-Journal design** — independently decide whether a typed cross-currency exchange transaction should join the current separate exchange event rail.

Candidate 1 is selected above. Actual-source routing, context, writer, reports, FX, valuation, exchange, and travel work remain unselected.

Selection rules:

- select at most one candidate;
- treat the completed admission owner as production evidence, not authorization to feed mixed-domain rows into current Stage 2A or context;
- ILS and USD are witnesses, not generic module branch conditions;
- the Journal container may be multi-currency while every ordinary transaction remains single-domain;
- do not bundle Stage 2A carrier work with context, writer work, travel metadata, reverse exchange, friend finalization, Wise semantics, or reports;
- never add amounts from different currency domains;
- reject mixed-domain ordinary transactions until an explicit typed exchange contract is selected;
- do not use private production data to determine policy;
- do not create accounts automatically;
- do not add FX, valuation, a reporting currency, a Currency axis, or mixed-currency aggregation automatically.

### Israel 2026 travel funding and settlement continuation

Status: non-JPY characterization, single-currency proof, multi-currency Journal contract, test-only container proof, and production complete-source admission complete; travel continuation slices remain independently unselected.

Canonical lifecycle plan:

- `docs/archive/active-plans/ISRAEL_ILS_CASH_LIFECYCLE_PLAN-2026-07-25.md`

Current ownership audit:

- `docs/archive/audits/ISRAEL_TRAVEL_RAIL_OWNERSHIP_CHARACTERIZATION-2026-07-25.md`

Recommended travel order after multi-currency Journal prerequisites:

1. **Native Journal ILS ordinary-add implementation** — depends on Stage 2A currency-proof carriage and selected-domain context composition in addition to the completed production admission boundary.
2. **Travel metadata admission** — separately decide and test `trip-id` and `payment`; do not infer support from the old TSV metadata path.
3. **Bidirectional account-explicit exchange** — widen the existing safe JPY→ILS event rail to admit ILS→JPY without inferring physical cash versus Wise from account names.
4. **Friend atomic JPY finalization writer** — durable finalization/status/index ownership plus exactly one Journal expense/liability append and recovery.
5. **Wise card evidence characterization** — distinguish existing-ILS-balance spending from purchase-time automatic conversion using public synthetic or user-supplied redacted statement shapes.
6. **Narrow per-account position and obligation read models** — physical ILS cash, Wise ILS balance, friend JPY liability, and confirmed own-card JPY spending kept separate.
7. **Synthetic whole-trip rehearsal** — prove no duplicated expense and zero-or-explained balances.
8. **Human-controlled production readiness checkpoint**.

Selection rules:

- select at most one candidate;
- do not bundle supported-currency Journal work with metadata, reverse exchange, friend finalization, Wise semantics, or reports;
- never add JPY and ILS;
- do not use private production data to determine policy;
- do not create accounts automatically;
- do not treat exchange as expense or friend repayment as another expense.

### Generic projection and valuation foundation

Status: unselected docs-only follow-up.

Canonical intake:

- `docs/archive/active-plans/GENERIC_PROJECTION_AND_VALUATION_FOUNDATION_DESIGN_INTAKE-2026-07-24.md`

Eligible finite candidates:

1. **Generic projection ownership inventory** — document the current owners of admission, axes, coordinates, exact grouping, dense materialization, provenance, rejection, Cube totals, and TBDS overlap.
2. **Commodity and valuation ownership inventory** — document the current owners of currency code, source quantity, precision, arithmetic authorization, formatting, mixed-currency rejection, and reporting selection.

Selection rules:

- select at most one inventory first;
- keep the first slice docs-only;
- do not refactor `cube.bqn` during the inventory;
- do not add a universal Cube, Currency axis, FX, valuation, mixed-currency aggregation, source-schema migration, or report output;
- keep the Canonical Daily Cube contract `Day × Account × Layer` unchanged;
- require a separate decision before any test-only primitive or runtime composition work.

### Configurable AI-assisted household ledger and report

Status: selected long-term direction; no next program slice selected.

Current source-truth boundary:

- human-readable native Journal for Actual transactions;
- human-readable TSV for companion/configuration sources;
- BQN-generated checked projections and reports;
- AI may explain and propose, but accepted changes pass through human judgment and approved editor paths.

Routing candidates remain independently unselected:

1. privacy-safe AI context-bundle contract;
2. one read-only AI consultation report;
3. safe proposal-to-editor handoff;
4. Ledger Observatory synthetic evidence-trace connection last.

Do not infer automatic advice, automatic TODO creation, automatic writes, or private production-data access.

### Bookkeeping matrix study extension

Status: unselected research direction. Use public synthetic, hand-checkable evidence only.

- Select one accounting topic at a time, such as depreciation, inventory, adjustments, closing, trial balance, or financial statements.
- Keep journal evidence, expected event-account matrix, manual accounting explanation, and BQN projection together.
- Do not turn this direction into a broad accounting-engine rewrite or production feature campaign automatically.

### Daily Capacity evidence adapter characterization

Status: unselected runtime follow-up.

Current evidence:

- `docs/DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION_CONTRACT.md`
- `docs/archive/audits/DAILY_CAPACITY_EVIDENCE_ADAPTER_PREIMPLEMENTATION_AUDIT-2026-07-15.md`
- `docs/archive/completed-plans/DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION-2026-07-15.md`

A future slice must choose exactly one of pure seam promotion, O-bounded account-balance facts, or pool/reservation facts. Do not combine them or infer policy from account names, prefixes, roles, country, cadence, or envelope names.

### Friend travel atomic finalization writer

Status: unselected / parked Israel continuation candidate.

- Current source-event semantics: `docs/archive/active-plans/FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md`.
- Reusable atomic-write proposal: `docs/archive/active-plans/FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md`.
- Pending source-event storage and safe append are already implemented.
- Finalization status/index persistence, atomic Journal append, production use, strict-source Steps 2–5, and M4 remain independently unselected.

### Mixed-ledger daily-use continuation

Status: production complete-source admission complete; residual routing and consumer candidates remain unselected.

- Current broad plan: `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md`.
- Israel lifecycle plan: `docs/archive/active-plans/ISRAEL_ILS_CASH_LIFECYCLE_PLAN-2026-07-25.md`.
- M3 and strict-source Step 1 are complete historically, but the native Journal runtime route still leaves ordinary Actual writing, Stage 2A carriage, context, and selected balances JPY-only.
- The production admission boundary can admit separate JPY and ILS ordinary transactions without mixed arithmetic, but current Actual loading and context do not yet consume that result.
- strict-source Steps 2–5 and M4 remain unselected and do not auto-start.
- multi-currency container work does not authorize mixed-currency arithmetic, valuation, or totals.

### Ledger Observatory long-term program

Status: active long-term direction; no runtime slice selected.

Canonical plan:

- `docs/archive/active-plans/LEDGER_OBSERVATORY_LONG_TERM_PLAN-2026-07-13.md`

The next eligible candidate remains a docs-only, synthetic-input source-row → Posting IR → Cube-coordinate evidence-trace contract. Scenario overlay, Cube Theatre, BQN Ledger Kata, Projection Workbench, and new AI-observation infrastructure do not auto-start.

Projection Workbench requires at least two independently completed consumers demonstrating the same projection contract.

### M4: expense breakdown grouped by meaning and currency

Status: candidate only.

Do not implement before daily-use observation and current expense/cycle consumer-contract review. Strict-source completion does not automatically select M4.

### `budget_pool=main` metadata

Status: docs-only future direction; current fallback remains valid.

- Cut any implementation plan into a finite slice.
- Decide fixture, check, and fallback compatibility before changing source TSV.

### Fintech engineering review backlog

Routes:

- `docs/FINTECH_ENGINEERING_REVIEW_BACKLOG.md`
- `docs/archive/active-plans/FINTECH_ENGINEERING_REVIEW_BACKLOG-2026-07-01.md`

Select one candidate only and classify it as `adopt-now`, `adopt-later`, `observe`, or `reject`. Even an adopted candidate must first become a finite docs-only design slice.

---

## Continuous maintenance

This section is a recurring review lane, not a permanently unfinished implementation queue.

### AI work quality / efficiency / accuracy

Purpose:

- improve AI work accuracy;
- reduce unnecessary rereading, token use, and debug iteration;
- keep failure evidence visible;
- make repository-specific safety boundaries difficult to misunderstand.

Use `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md` as evidence input. Feedback does not automatically authorize tools, telemetry, lint, refactors, or implementation work.
