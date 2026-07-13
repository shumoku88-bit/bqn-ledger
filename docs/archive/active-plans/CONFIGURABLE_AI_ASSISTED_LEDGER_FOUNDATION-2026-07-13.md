# Configurable AI-assisted Ledger Foundation — 2026-07-13

Status: active routing map / selected highest-priority development direction; foundation synthesis and PR #219 integration are complete, and no next program slice is selected
Owner: config / report / AI consultation / privacy
Canonical: no; finite-work selection remains in `TODO.md`
Exit: replace this synthesis with separately approved finite contracts, then archive when the program is completed, superseded, or declined.

## Purpose

Build a **Configurable AI-assisted Household Ledger and Report**（設定可能なAI協働型家計簿・レポート基盤）while preserving human-readable TSV and configuration files as source truth.

User-specific currencies, accounts, life cycles, classifications, budget policy, presentation, and privacy boundaries should be definable without changing accounting code when they are genuinely configuration. BQN derives evidence-bearing data and reports from those sources. AI does not control source truth: it reads approved evidence, explains it, proposes candidates, and reaches writes only after human judgment through the existing preview, confirmation, safe-write, post-check, and rollback path.

This plan is a synthesis and routing map. It adds no config key, schema, runtime, export, report section, AI agent, or source write.

## Current priority and dependency order

0. Complete Israel real-account readiness as the small read-only operational preparation already selected in `TODO.md`.
1. Treat the latest AI working feedback, completed by PR #227, as observation evidence only. It authorizes no automatic implementation.
2. PR #219 (`refactor: centralize built-in currency policy`) is integrated and current-main verified. It centralizes built-in JPY/ILS admission and lexical precision policy as a code-level registry seam, not user configuration.
3. The foundation synthesis was completed by PR #228. It selects no later runtime slice.
4. Inventory configuration ownership before adding keys.
5. Design a privacy-safe AI context-bundle contract.
6. Select one read-only AI consultation report only after its evidence contract exists.
7. Design a safe proposal-to-editor handoff without granting AI write authority.
8. Connect PR #211 Ledger Observatory last, as the source-to-derived evidence telescope after the config, privacy, and consultation boundaries are established.

The order is routing, not blanket authorization. Steps 4–8 require separate finite selection; completion of #219 and the synthesis does not authorize the next row.

## Foundation map

```text
human-readable source TSV + configuration
  -> BQN validation / Posting IR / selected-currency derivation
  -> report ViewModels and structured evidence
  -> privacy-safe AI context bundle
  -> AI explanation / candidate proposal
  -> human decision
  -> editor preview and explicit confirmation
  -> checked safe write / post-check / rollback

later evidence telescope:
source row -> Posting IR -> Cube coordinate -> report value -> AI explanation
```

### A. Configuration ownership inventory

| Meaning | Current owner | Hard-coded / configured today | Externalization value | Failure contract to decide | Kind |
|---|---|---|---|---|---|
| Ledger-level defaults and typed policy | `<base>/config.tsv` plus config defaults/resolution | mixed; some keys configured, built-in admissible values remain code-owned | high when user-specific and stable | missing / duplicate / unknown / empty must be explicit per key | source policy or initial view selection; never source amount authority |
| Account identity, role, currency, type, budget mapping | `<base>/accounts.tsv` | metadata-configured, with documented compatibility behavior | already the primary user-owned semantic surface | malformed/duplicate/unknown account metadata fail closed | source meaning |
| Life/accounting cycle | `<base>/cycle.tsv` and cycle owner | configured | already appropriate; future cadence rules need owner review | invalid/missing/duplicate cycle declarations must not be guessed | source meaning / query boundary |
| Journal/plan extension metadata vocabulary | `config/meta_schema.tsv`, `docs/JOURNAL_META.md`, source contracts | partly schema-defined; generic safe `key=value` remains available | useful only for durable source meaning | key/value admission and unknown policy must be selected before implementation | source meaning |
| Built-in currency admission and lexical precision | `src_next/currency_setup.bqn` registry integrated by PR #219 | code-owned JPY/ILS policy | established seam toward adding supported currencies without scattered edits; not a user-editable setting yet | unsupported currency and invalid precision fail closed | fixed engine admission policy until separately externalized |
| Report labels, section/view selection and formatting preferences | `config/report_labels.tsv`, report modules, structured export contracts | mixed | high for presentation choices that do not redefine accounting | unknown/missing presentation keys need explicit fallback or failure | view preference |
| Privacy/export policy | safety docs and individual structured exports; no single user policy owner yet | mostly contract-owned | high before AI context export | default deny; unknown or missing policy must not widen disclosure | export policy |
| AI context policy | no runtime owner; this synthesis only | not implemented | high for selecting period/currency/evidence and redaction | missing policy means no private bundle, not broad export | consultation/export policy |

The inventory must distinguish a source meaning from a view preference. Canonical Daily Cube shape, axes, and Layer meaning are fixed contracts, not user settings. Configuration must not become a DSL or arbitrary accounting program.

### B. Mixed currency and Israel reference profile

Israel is the first proven reference profile, not a special hard-coded product mode. Existing synthetic evidence proves:

- JPY/ILS accounts and journal rows;
- selected-currency balances without cross-currency addition;
- ILS cash spending and confirmed-JPY-only card spending;
- JPY-to-ILS exchange source events;
- friend-paid pending source events;
- mixed-currency journal source lint;
- checked rollback and later-writer protection.

PR #219 completed the immediate currency-policy dependency by gathering supported built-in currencies and lexical precision into one BQN owner. It did not create user configuration, add a Currency axis, enable FX, or authorize additional currencies.

Future generalization candidates are profile/trip identity, supported currencies, payment methods, exchange-event policy, pending third-party-payment policy, and confirmed-card-amount policy. This synthesis adds none of those keys or schemas. It must not embed `israel-2026`, real account names, private paths, or private values into general configuration.

### C. AI working feedback connection

The current loop remains:

```text
intake -> classification -> approved finite plan -> implementation -> verification -> learning
```

PR #227 added four relevant observations to [AI_WORKING_FEEDBACK_LOG.md](AI_WORKING_FEEDBACK_LOG.md). Their synthesis classification is evidence only:

| Feedback | Primary / secondary layer | Relevance here |
|---|---|---|
| Public-command fidelity | verification / workflow | consultation and editor handoff must rehearse exact documented public commands |
| Green-path output volume | tool / verification | future AI bundles and checks should be compact on success and complete on failure |
| Coverage bytecode residue | tool/environment | local hygiene observation; unrelated to ledger semantics |
| Closing PR merge-hash self-reference | workflow/information architecture | completion evidence should name a non-self-referential owner |

No row in this table becomes a TODO or implementation permission automatically.

### D. Privacy-safe AI context bundle direction

Do not send raw private TSV wholesale. A future structured contract may contain only explicitly selected and BQN-owned fields such as:

```text
ledger configuration summary
selected reporting period
selected currency
aggregated report values
source-to-derived evidence references
privacy-safe identities
diagnostics
open user decisions
```

The contract must define required/optional fields, provenance, unavailable/error representation, ordering where relevant, and redaction/default-deny behavior. It must consume structured exports or ViewModels, never parse human report prose.

Forbidden:

- unconditional export of private raw rows;
- publication of secrets, account numbers, personal names, private paths, or private amounts outside an explicitly approved local boundary;
- AI direct edits to source TSV;
- human-report text parsing as a machine API;
- advice without BQN-owned evidence;
- automatic TODO generation or production writes.

### E. Consultation and write separation

```text
AI consultation / explanation / candidate generation
  -> human judgment
  -> editor preview
  -> explicit confirmation
  -> safe write
  -> post-check / checked rollback
```

Read-only consultation calculations remain BQN-owned; the existing envelope calculator is a concrete example. A future consultation report must identify its reporting period, selected currency, evidence and unavailable states, and must not silently convert a recommendation into an edit.

### F. Ledger Observatory placement

PR #211 remains valuable, but it is deliberately last in this program's sequence. Once configuration ownership, privacy-safe bundle shape, and one consultation consumer are concrete, Observatory can connect:

```text
source row -> Posting IR -> Cube coordinate -> report value -> AI explanation
```

Its first eligible candidate remains the pure synthetic source-row-to-Cube evidence-trace design. This synthesis does not start that runtime work, production reads, CLI/report wiring, scenario overlay, Cube Theatre, Kata, Projection Workbench, telemetry, or generic tracing infrastructure.

## Roadmap and selection gates

| Order | Candidate | Current authorization |
|---:|---|---|
| 0 | Israel real-account readiness | selected read-only operational preparation |
| 1 | Latest AI feedback record | completed evidence; no implementation authorization |
| 2 | PR #219 built-in currency policy integration | completed and current-main verified; built-in code policy only |
| 3 | Foundation synthesis docs | completed by PR #228; this document remains the routing map |
| 4 | Config ownership inventory refinement | not selected separately |
| 5 | Privacy-safe AI context-bundle contract | not selected |
| 6 | One read-only AI consultation report | not selected |
| 7 | Safe proposal-to-editor handoff | not selected |
| 8 | PR #211 synthetic evidence-trace design / Observatory connection | last; not selected |

Completing an earlier row does not authorize the next row.

## Explicit non-goals

- generic AI-agent runtime or chatbot UI;
- cloud service, authentication, telemetry, or automatic task queue;
- source TSV automatic editing or automatic production writes;
- automatic budget advice;
- dataframe/query framework, Projection Workbench, or broad report rewrite;
- Currency axis, FX conversion, valuation, market rates, or cross-currency totals;
- scenario overlay, Cube Theatre, or Kata;
- candidate 6 friend finalization;
- strict-source Steps 2–5 or M4;
- private production-data access;
- any config/schema/runtime change in this synthesis PR.

## Exit criteria for the synthesis slice

- Israel readiness remains the first small operational task;
- PR #219 is integrated as the currency-policy seam before program expansion;
- config ownership, mixed-currency/Israel evidence, AI feedback, privacy bundle, consultation/write separation, and Observatory placement share one map;
- only docs change;
- feedback remains evidence, not authorization;
- Observatory is routed last;
- candidate 6, strict-source Steps 2–5, M4, and all runtime work remain unselected by this plan.
