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
- Native Journal ordinary Actual writing, parsing, and selected balances remain JPY-only; ordinary ILS travel spending is not currently admitted.
- The non-JPY single-currency characterization and test-only admission proof are complete. Public-synthetic ILS and USD witnesses share one registry-driven domain, precision, account-currency, normalization, balance, and structural-trace boundary while production Journal routes remain unchanged.
- The multi-currency Journal container contract decision is complete: one Journal may contain multiple supported currencies while every ordinary transaction remains single-domain and unlike currencies are never aggregated.
- The generic projection and valuation foundation remains an active backlog, not implementation authorization.
- Detailed completion history through the previous checkpoint is in `docs/archive/TODO_HISTORY-2026-07-24.md`.

---

## Active work

**No finite implementation slice is currently selected.**

Completed current finite work:

- `docs/archive/active-plans/MULTI_CURRENCY_JOURNAL_CONTAINER_CONTRACT-2026-07-25.md`

Recorded decision:

- one native Journal file may contain ordinary transactions from multiple registry-supported currencies;
- every ordinary transaction has exactly one currency domain and balances within that domain;
- no Journal-wide money total or arithmetic domain is implied;
- an ordinary transaction containing more than one currency fails closed;
- cross-currency exchange remains a separately typed rail until an explicit exchange-in-Journal contract is independently selected.

The completed contract does not authorize production parser, writer, Stage 2A, context, Cube, TBDS, reports, metadata, FX, valuation, source-data, account, or travel changes.

The latest AI working feedback remains evidence only and does not authorize additional work.

---

## Next candidates

### Multi-currency native Journal container continuation

Status: contract decision complete / all implementation continuation slices independently unselected.

Current evidence and contract:

- `docs/archive/audits/NATIVE_JOURNAL_NON_JPY_SINGLE_CURRENCY_ADMISSION_CHARACTERIZATION-2026-07-25.md`
- `src_next/journal_supported_single_currency_admission_for_test.bqn`
- `tests/test_journal_supported_single_currency_admission_proof.bqn`
- `docs/archive/active-plans/MULTI_CURRENCY_JOURNAL_CONTAINER_CONTRACT-2026-07-25.md`

Recommended candidate order:

1. **Test-only multi-currency Journal container proof** — one public-synthetic raw Journal containing separate balanced JPY and ILS ordinary transactions, plus USD as a second generality witness; mixed-domain ordinary transactions fail closed.
2. **Production complete-source admission implementation** — return transaction-domain and calculation-scale evidence without silently widening `historical_external_plan` or manufacturing one Journal-wide domain.
3. **Stage 2A currency-proof carrier decision and implementation** — retain posting domain, scale, normalized coefficient, account-currency proof, and provenance.
4. **Selected-domain context composition** — compose Actual + plan + budget for exactly one selected currency at a time or explicitly separate partitions; do not add a Currency axis automatically.
5. **Native ordinary-add writer widening** — accept one explicit supported transaction currency while preserving existing JPY behavior.
6. **Per-domain consumer and formatting verification** — selected balances and immediate consumers never produce combined multi-currency totals.
7. **Explicit exchange-in-Journal design** — independently decide whether a typed cross-currency exchange transaction should join the current separate exchange event rail.

Selection rules:

- select at most one candidate;
- treat the merged ILS and USD proof as evidence, not production authorization;
- ILS and USD are witnesses, not generic module branch conditions;
- the Journal container may be multi-currency while every ordinary transaction remains single-domain;
- do not bundle parser/writer work with travel metadata, reverse exchange, friend finalization, Wise semantics, or reports;
- never add amounts from different currency domains;
- reject mixed-domain ordinary transactions until an explicit typed exchange contract is selected;
- do not use private production data to determine policy;
- do not create accounts automatically;
- do not add FX, valuation, a reporting currency, a Currency axis, or mixed-currency aggregation automatically.

### Israel 2026 travel funding and settlement continuation

Status: non-JPY characterization and test-only proof complete; multi-currency Journal container contract complete; travel continuation slices remain independently unselected.

Canonical lifecycle plan:

- `docs/archive/active-plans/ISRAEL_ILS_CASH_LIFECYCLE_PLAN-2026-07-25.md`

Current ownership audit:

- `docs/archive/audits/ISRAEL_TRAVEL_RAIL_OWNERSHIP_CHARACTERIZATION-2026-07-25.md`

Recommended travel order after multi-currency Journal prerequisites:

1. **Native Journal ILS ordinary-add implementation** — depends on production complete-source admission, Stage 2A currency-proof carriage, and selected-domain context composition.
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

Status: single-currency characterization and proof complete; multi-currency Journal container contract complete; residual runtime candidates remain unselected.

- Current broad plan: `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md`.
- Israel lifecycle plan: `docs/archive/active-plans/ISRAEL_ILS_CASH_LIFECYCLE_PLAN-2026-07-25.md`.
- M3 and strict-source Step 1 are complete historically, but the native Journal cutover leaves current ordinary Actual writing/parsing JPY-only.
- A future Journal may contain separate JPY and ILS ordinary transactions, but current production parsing and context do not yet admit them.
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
