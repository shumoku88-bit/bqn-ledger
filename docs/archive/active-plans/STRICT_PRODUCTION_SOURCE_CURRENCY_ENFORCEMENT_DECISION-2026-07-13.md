# Strict Production Source Currency Enforcement Boundary Decision — 2026-07-13

Status: active plan / Step 1 selected; docs-only boundary decision remains canonical
Owner: currency
Canonical: yes
Exit: after the decision PR merges, authorize only the first implementation slice below; archive as completed after strict runtime activation and separate post-implementation verification

## Problem statement

Currency Mixed-Ledger M1 through M3 and the M2.5 production migration are complete and separately verified. Production source now has one explicit `currency=` token on monetary accounts and journal-like rows, but current runtime still has two legacy JPY fallbacks:

- `context.BuildRowEvidenceForLine`: missing journal-like row currency becomes JPY with `provenance="legacy_compatibility"`;
- `account_key.CurrencyFromMeta`: missing account currency becomes JPY.

Those fallbacks remain useful to focused compatibility and migration evidence. They must not remain implicit source authority on daily production-capable reads. Conversely, deleting them globally would break unrelated historical fixtures and erase evidence about the compatibility contract. This decision selects the boundary without implementing it.

The configured `DEFAULT_CURRENCY` remains view-selection policy only. It must never repair or reinterpret missing source currency.

## Current fallback map

| Location | Current behavior | Current callers / consequence | Decision |
|---|---|---|---|
| `src_next/context.bqn` `BuildRowEvidenceForLine` | no row token -> JPY, `legacy_compatibility` | ordinary `BuildContext`, Stage 2 proof tests, selected projection | retain low-level evidence behavior for an explicit compatibility lane; strict admission rejects before arithmetic or projection |
| `src_next/account_key.bqn` `CurrencyFromMeta` | no account token -> JPY | `Resolve` and many old JPY fixtures | retain compatibility resolver behavior; strict admission rejects before `Resolve` becomes calculation authority |
| `src_next/currency_setup.bqn` `ResolveDefault` / `ResolveSelection` | config default selects JPY/ILS view | M2 editor selection and M3 balances selection | keep; never use as source admission fallback |
| `src_next/currency_setup.bqn` `AuditFile` | classifies missing/duplicate/unknown and migration proposals | M1.5/M2.5 migration; M3 account precheck | reuse concepts, not migration target semantics; strict admission needs a checked, non-proposing result |
| `src_next/currency_selection.bqn` | validates row evidence and account mismatch after evidence/resolution | selected balances path | strict admission must precede this path; mismatch checks remain independent |
| `src_next/balances.bqn` `BuildSelected` | audits accounts, but missing is a migration proposal rather than a fatal result; rows still use context fallback | human selected balances | must receive the same strict source policy as ordinary report paths |

## Production-capable entrypoint inventory

“Production-capable” is determined by an explicit policy carrier at the orchestration call site, never by the base-directory string, `LEDGER_DATA_DIR` value, existence of a private path, or path comparison.

### Public read paths that must select strict policy

| Public surface | Route | Required policy after activation |
|---|---|---|
| `tools/report` | `src_next/report.bqn` -> ordinary `BuildContext` or selected `balances.BuildSelected` | strict for full report, every human section, section cache, and existing JSON sections; selected balances is not an exception |
| `tools/main-ui.sh`, `tools/bl` report/section | delegates to `tools/report` | inherit strict; no separate switch |
| MCP report/preflight/post-write reads | `mcp-server/core.js` -> `tools/report` | inherit strict |
| `tools/report-next` | `src_next/main.bqn` -> `BuildContext` | strict despite “diagnostic” label because it accepts the production base default |
| `tools/report-next-summary` | `src_next/summary.bqn` -> `BuildContext` | strict |
| `tools/query` | delegates to `tools/report-next-summary` | inherit strict |
| `tools/envelope-calc` | `src_next/calc/main.bqn` -> `BuildContext` | strict |

Direct BQN module tests and dedicated migration commands are not public production read policy merely because they can receive a directory argument. They must choose an explicit policy in their test/migration orchestration.

### Write paths and their relation to this read policy

The public write route is `tools/add-ui.sh` / MCP commit -> `tools/edit` -> `tools/edit-bqn` -> `src_edit/*` -> safe-write helpers.

- `account add` and `journal add` already render explicit currency.
- `journal reverse` preserves original metadata, and `plan finish` preserves plan metadata.
- `plan add` and `budget add` can currently render a new row without currency; this is a concrete activation prerequisite, not a reason to weaken the read policy.
- The strict admission API belongs to read orchestration. Writer changes remain separate, narrowly authorized slices. Public strict read activation must wait until production-capable writers are proven not to create a missing-currency row.
- The production TSV migration is complete. No implementation slice should plan another production source rewrite.

## Considered designs

### Selected: explicit policy carrier plus pre-projection source admission

Introduce a small policy namespace/carrier with closed values such as:

```text
source_currency_policy.production_strict
source_currency_policy.legacy_compatibility
```

Add a pure source-admission operation over account lines and the already loaded posting snapshot. In strict mode it returns a checked result containing either admitted source evidence or structured diagnostics. Admission happens:

1. after source lines/snapshot are loaded once;
2. before `account_key.Resolve` is accepted as account identity authority;
3. before row arithmetic, currency selection/filtering, Posting IR, Cube, TBDS, or rendering.

The public orchestration APIs must make policy visible at the call site, for example a future `BuildContextWithPolicy ⟨query, policy⟩`. Public read entrypoints pass `production_strict`. Dedicated compatibility tests pass `legacy_compatibility`. A compatibility convenience wrapper may exist only if its name contains `Compatibility`; an unlabelled silent compatibility default must not be added to a new public orchestration API.

The low-level parsers may continue producing legacy evidence in compatibility mode. Strictness is an admission decision, not a configured default and not an inference from paths.

### Why this fits current architecture

- `context.bqn` already owns one-snapshot orchestration and the gate before projection.
- `currency_setup.AuditFile` proves that pure classification is feasible, but migration proposal generation and strict admission should not be conflated.
- `currency_selection.Build` already requires checked evidence before selected projection; strict admission can precede it without adding a Currency axis or widening Posting IR.
- Both ordinary reports and M3 selected balances can share one source contract before their paths diverge.

## Rejected alternatives

1. **Delete both global JPY defaults immediately.** Rejected because it couples parser/API breakage, fixture migration, production activation, and proof-contract changes; it also destroys an intentional compatibility test lane.
2. **Use `LEDGER_DATA_DIR`, a private path prefix, or “not under fixtures/” to detect production.** Rejected as non-portable, privacy-sensitive, and semantically false. Paths do not define policy.
3. **Environment variable or ledger config strict-mode toggle.** Rejected for activation: a forgotten or user-controlled toggle would let a production-capable read silently retain fallback. `DEFAULT_CURRENCY` is view policy, not source authority.
4. **Public `--compat-currency` report flag.** Rejected because it creates an easy production bypass and spreads fixture policy into the daily CLI. Compatibility belongs in explicit test/module orchestration and migration tooling.
5. **Strict only for `--section balances --currency`.** Rejected because ordinary reports, JSON, summary, diagnostics, and envelope calculation would still accept implicit source meaning.
6. **Audit after account resolution or after selected-currency filtering.** Rejected because fallback could already shape AccountKey identity, and unselected malformed rows could be hidden.
7. **Use configured default to fill missing source currency.** Rejected because it changes source meaning when view config changes.
8. **Combine strict activation with M4 or broad fixture normalization.** Rejected as unrelated scope and difficult to review or roll back.

## Selected production boundary

After the separately authorized implementation sequence completes:

- every production-capable public read path listed above selects `production_strict` explicitly;
- strict admission covers `accounts.tsv`, required `journal.tsv`, and present `plan.tsv` / `budget_alloc.tsv` as one source snapshot;
- strict admission completes before account resolution is trusted and before any projection;
- a failure returns nonzero and emits no partial Posting IR, Cube, TBDS, balance, JSON, cache, or report section;
- selected balances and ordinary report paths use the same source-admission contract;
- read strictness is separate from editor validation, while writer closure is an activation prerequisite;
- no policy is derived from an actual path or private data location.

## Compatibility fixture and test inventory

This is a disposition inventory, not permission for bulk deletion or bulk rewriting.

| Category / evidence | Current dependency | Disposition |
|---|---|---|
| **Source contract regression:** `fixtures/src-next-golden`, `fixtures/basic`, `fixtures/src-next-income-anchor-golden`, plus section-specific untagged JPY fixtures | broad report/summary/section contracts currently depend incidentally on account and row fallback | **follow-up with explicit metadata**, fixture by fixture as its public-entrypoint use is activated; extract a minimal dedicated legacy fixture before converting `src-next-golden`; do not rewrite all fixtures in one PR |
| **Migration input:** `fixtures/currency-m15-migration`, `tests/test_src_next_currency_setup.bqn`, `checks/check-currency-m15-setup.sh` | missing rows are the subject under test; apply check also uses temporary copies of public sandbox data | **migration test only**; explicitly select migration/compat classification and keep missing rows |
| **Old JPY compatibility:** missing-currency cases in `tests/test_src_next_currency_domain_proof.bqn`, `tests/test_src_next_account_key.bqn`, and `fixtures/src-next-empty-projection` | proves `legacy_compatibility`, empty-source identity, and old AccountKey fallback | **maintain compatibility**, but narrow it to named module-level compatibility calls/fixtures; do not send it through production-capable entrypoints |
| **Synthetic mixed currency:** `fixtures/src-next-currency-mixed-selected`, `tests/test_src_next_currency_selection.bqn` | account and row currency are already explicit | **move to strict**; retain no compatibility selection |
| **M3 production-shaped subset:** `fixtures/currency-m3-balances`, `tests/test_src_next_balances.bqn`, `checks/check-currency-m3-balances.sh` | explicit account/row currency and default config, but only balances scope | **move to strict**; useful entrypoint evidence, but not a claim that a private production ledger was copied |
| **Editor M2:** `fixtures/editor-currency-m2`, `checks/check-edit-bqn-currency-m2.sh` | explicit metadata for account/journal write behavior | **move to strict where a read admission is exercised**; otherwise retain as writer evidence |
| **Stage 2 explicit-row / implicit-account:** `fixtures/src-next-currency-b3-jpy-normalized`, `fixtures/src-next-currency-c-ils-normalized`, related B3/C tests | account fallback is incidental to row arithmetic proof | **follow-up with explicit metadata** on accounts; arithmetic expectations remain unchanged |
| **Historical AccountKey currency fixture:** `fixtures/src-next-currency-accountkey` and golden/summary checks | contains unsupported account currency plus implicit rows; mixes resolver history with report execution | **evidence insufficient; hold** until compatibility-lane preparation separates the low-level AccountKey assertion from public report expectations |
| **Public sandbox `data/`** | anonymous daily sandbox; currently untagged and used via temporary migration copies | **follow-up with explicit metadata** only in a separate reviewed source-fixture change; it is not production-equivalent and never selects policy by path |
| **Current production-equivalent fixture** | no committed fixture represents the private production ledger, and none should | **evidence insufficient; create a synthetic strict full-read fixture** from public semantics in a later slice; never copy private rows, paths, or amounts |
| **Other untagged domain fixtures** | temporal, envelope, unknown-account, empty-field, and other focused tests mostly use old JPY fallback incidentally | **evidence insufficient per fixture until touched**; compatibility may be explicit temporarily, then each fixture is either metadataized or retained as a named compatibility case based on its actual assertion |

The compatibility lane is therefore finite in meaning: migration inputs, a minimal old-JPY source contract, and low-level parser/resolver evidence. “All existing fixtures” is not a compatibility classification.

## Runtime API shape

The implementation design target is:

```text
Load account lines + one posting snapshot
  -> AdmitSourceCurrency(policy, account lines, snapshot)
       strict: checked success or complete diagnostics
       compatibility: preserve explicit legacy evidence
  -> only on success: Resolve accounts / build row evidence
  -> currency selection (if any)
  -> arithmetic proof
  -> Posting IR -> Cube/TBDS -> rendering
```

Required API properties:

- policy is a closed namespace/value, not a free-form Boolean whose meaning is hidden;
- strict/compat meaning is visible in orchestration call sites;
- pure admission returns data; it does not print, exit, read files, or render reports;
- the fatal shell/BQN boundary converts an error result to one nonzero exit before projection;
- `CurrencyFromMeta` and `BuildRowEvidenceForLine` remain compatibility primitives until dedicated callers are migrated; no global default removal is authorized by this decision;
- selected and non-selected paths consume the same admission result or same strict policy contract.

## Diagnostic contract

Strict admission diagnostics use structured fields before a public boundary formats them:

```text
severity: error
stage: source_currency_admission
code: account_currency_missing | account_currency_empty |
      account_currency_duplicate | account_currency_unsupported |
      row_currency_missing | row_currency_empty |
      row_currency_duplicate | row_currency_unsupported
source_kind: account | journal_like
source_file: accounts.tsv | journal.tsv | plan.tsv | budget_alloc.tsv
source_row: zero-based index in the loaded source line array
message: safe summary containing source file, row index, and classification only
```

Contract requirements:

- account and journal-like diagnostics have distinct codes;
- missing, empty, duplicate, and unsupported are distinct;
- only the allowlisted source basename and row index are emitted; never base directory/private path;
- message and structured output contain no source row text, memo, account name, amount, or unsupported raw token;
- diagnostics may collect all source-currency admission failures, but no downstream calculation starts when any exist;
- public entrypoints exit nonzero;
- stdout/stderr placement may follow existing CLI convention, but report/JSON/cache payload must not be emitted;
- `DEFAULT_CURRENCY` is not consulted by admission.

## Activation sequence

The recommended order is changed from “strict report first, compatibility later” because current public `plan add` and `budget add` can still create missing currency, and broad report fixtures use fallback incidentally.

1. **Policy carrier + pure admission (authorized first implementation slice).** Add the closed policy namespace, pure account/row classifier, structured diagnostics, and unit tests over synthetic in-memory lines/snapshots. Do not change existing public entrypoint behavior or fallback functions.
2. **Writer prerequisite closure (not yet authorized).** Select a separate finite slice so `plan add` and `budget add` cannot create missing currency; verify preservation paths (`plan finish`, `journal reverse`) reject or preserve exactly one explicit token. No production source edit.
3. **Compatibility-lane preparation (not yet authorized).** Add/narrow named compatibility orchestration for the migration and old-JPY tests; metadataize only the first public-report fixture set needed for activation; split ambiguous `src-next-currency-accountkey` evidence rather than bulk rewriting it.
4. **Production-capable read activation (not yet authorized).** Pass strict policy from all inventoried public read roots, including ordinary report and selected balances. Use a synthetic explicit-currency full-read fixture and prove missing account and each journal-like source fail before projection/rendering.
5. **Post-implementation verification (not yet authorized).** Separate docs-only claim-to-evidence review tied to exact implementation heads and CI.

Each step requires separate selection. Completing step 1 does not authorize steps 2–5.

## Authorized first implementation slice

Only the following runtime follow-up becomes eligible after this decision PR merges; it is not implemented by this PR:

- add one explicit source-currency policy carrier with `production_strict` and `legacy_compatibility` values;
- add a pure admission function for supplied account lines and supplied posting snapshot;
- classify account and journal-like missing/empty/duplicate/unsupported states with the diagnostic contract above;
- add focused unit tests using synthetic in-memory source only;
- prove strict error results contain no admitted/projection rows and compatibility classification retains current JPY evidence semantics;
- leave `tools/report`, `BuildContext`, low-level fallbacks, fixtures, writers, and production source unchanged.

Exit evidence: focused unit tests, full `tools/check.sh`, `tools/coverage`, and a diff containing only the narrow module/test/docs updates selected by that future PR.

## Explicit non-goals

This decision does not authorize:

- runtime enforcement in this docs PR;
- deletion of either fallback;
- bulk fixture rewrite or deletion;
- production source reads, migration, or changes;
- M4;
- report section additions;
- JSON widening;
- FX, conversion, valuation, mixed-currency totals, or a Currency axis;
- Posting IR widening;
- broad Stage 3 campaign work;
- a user-facing strict/compat toggle;
- path-based production detection.

## Verification requirements for later implementation

- pure tests for every account/row classification and both policies;
- source-file coverage for `accounts.tsv`, `journal.tsv`, `plan.tsv`, and `budget_alloc.tsv`;
- public read negative tests prove nonzero exit and absence of report, JSON, cache, Posting IR, Cube, TBDS, and partial balances;
- ordinary full report, selected balances, JSON section, summary/query, diagnostic, envelope calculator, UI delegation, and MCP delegation are mapped to strict roots without duplicate policy logic;
- dedicated migration and old-JPY tests name compatibility explicitly;
- first-five-column, exact-decimal, single-domain, account mismatch, and M3 display contracts remain green;
- full repository check and coverage pass;
- separate post-implementation verification records exact heads and CI.

## Privacy boundary

Design and tests use repository fixtures, temporary copies, or in-memory synthetic rows only. Do not resolve, inspect, print, or copy actual `LEDGER_DATA_DIR` content. Diagnostics expose only an allowlisted source basename, zero-based row index, and classification. No private path, memo, account name, row text, amount, or raw unsupported value is permitted.

## Rollback and compatibility stance

Before public activation, rollback is removal of the new unused policy/admission module. During activation, strict policy is wired at public roots in one finite PR only after writer and fixture prerequisites are green; rollback restores those call sites without changing source data.

Compatibility remains explicit and narrow. Migration inputs and a minimal old-JPY parser/resolver lane retain fallback behavior. Production-capable reads never infer compatibility from a path and expose no compatibility CLI/config/environment switch. Fixture conversion is incremental and reviewed; no mass rewrite is required for rollback.
