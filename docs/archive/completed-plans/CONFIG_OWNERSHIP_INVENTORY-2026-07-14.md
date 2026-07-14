# Config ownership inventory — 2026-07-14

Status: completed docs-only inventory
Owner: config / source semantics / presentation / export policy
Canonical: no; current behavior remains owned by the referenced source contracts and runtime modules
Exit: archived completion record; any config or schema change requires a separately selected concrete consumer and focused tests

## Purpose

Refine the configuration-ownership row in `CONFIGURABLE_AI_ASSISTED_LEDGER_FOUNDATION-2026-07-13.md` before adding keys or designing an AI context bundle.

This slice classifies current ownership boundaries only. It adds no config key, source schema, runtime behavior, report section, AI export, source read, or source write.

## Ownership classes

| Class | Meaning |
|---|---|
| source meaning | Human-owned ledger facts or declarations that affect accounting identity, classification, or query boundaries. |
| ledger policy | A ledger-specific choice interpreted by checked BQN code; it is never source amount authority. |
| engine admission policy | Repository-owned supported-value and lexical rules required before a value may enter arithmetic. |
| view preference | Presentation, ordering, interaction, or diagnostic selection that must not redefine source meaning. |
| runtime bootstrap | Installation and path defaults used to locate files; not household accounting meaning. |
| export / consultation policy | Disclosure and consultation boundaries. Missing ownership must fail closed rather than widen export. |
| fixed contract | Architecture that is deliberately not configurable. |
| unresolved / quarantined | Current ownership is mixed, dormant, or insufficiently evidenced. No migration is authorized. |

## Current ownership inventory

| Meaning | Current owner | Class | Current decision |
|---|---|---|---|
| Base directory and standard source filenames | `config/system_defaults.tsv`, `src_next/config.bqn` system-default accessors, shell entry points | runtime bootstrap | Repository/operator defaults only. They locate ledger files and do not define household meaning. |
| Ledger policy rows in `<base>/config.tsv` | local `config.tsv`, `config/default_config.tsv`, typed accessors in `src_next/config.bqn` | mixed ledger policy / view preference / unresolved | Shared physical storage does not imply one semantic owner. Each key keeps its current focused contract; no global resolver or unknown-key policy is selected. |
| `HOUSEHOLD_GROUP_LIFE`, `HOUSEHOLD_GROUP_RESERVE` | local config with repository defaults and effective defaultable accessors | ledger policy | Approved sparse overrides. Missing uses the repository default; explicit empty fails closed. |
| `POLICY_BUDGET_STYLE` | typed accessor in `src_next/config.bqn` | ledger policy | Current enum and fallback remain. It selects a household budget policy, not transaction facts. |
| `POLICY_RISK_STYLE` | typed accessor and outlook consumer | ledger policy / derived-view policy | Current enum and fallback remain. It affects derived interpretation, not source amounts or account identity. |
| `EXECUTION_PLANNED_PAYMENTS_ENVELOPE` | config accessor and envelope diagnostic consumer | view preference / optional diagnostic selector | Empty disables the diagnostic. It must not become envelope source meaning. |
| `POLICY_INCOME_CADENCE` | dormant typed accessor | unresolved / quarantined | No current canonical consumer proves runtime meaning. Keep frozen; do not force or default it through inventory work. |
| `HOUSEHOLD_GROUP_ORDER` | local config and current ordering consumers | unresolved / quarantined | Remains `derived-candidate`. Do not decide whether it is independent, derived, or replaced in this slice. |
| `BUDGET_PREFIX`, `BUDGET_ID_*` | legacy config accessors plus metadata/literal fallback paths | unresolved / quarantined | Remain `legacy-contract-review`. No cleanup, migration, or new default is authorized. |
| Terminal theme and fuzzy-preview layout | shared local config consumers in shell/UI | view preference | UI-only. Application config resolution must not become their semantic owner merely because rows share one file. |
| Account identity, type, role, currency, and budget mapping | `<base>/accounts.tsv` and account validation/loaders | source meaning | Primary user-owned semantic surface. Malformed, duplicate, unknown, or currency-incompatible account metadata must fail closed at the relevant consumer. |
| Life/accounting cycle declarations | `<base>/cycle.tsv` and cycle loaders | source meaning / query boundary | Already configured in the correct source. Missing or invalid cycle declarations must not be guessed from config defaults. |
| Journal and plan facts | `<base>/journal.tsv`, `<base>/plan.tsv` | source meaning | First five columns remain contract; admitted `key=value` metadata extends facts without moving fact ownership into `config.tsv`. |
| Metadata vocabulary and scoped admission | `config/meta_schema.tsv`, `docs/JOURNAL_META.md`, source validators | source-schema admission | Durable metadata meaning may be schema-owned. Generic metadata availability does not authorize automatic promotion of every observed key into policy config. |
| Built-in currency support and lexical precision | `src_next/currency_setup.bqn` registry integrated by PR #219 | engine admission policy | JPY/ILS support remains code-owned. It is not user-editable configuration, a Currency axis, FX policy, or valuation policy. |
| Report labels | `config/report_labels.tsv` and report formatters | view preference / repository presentation catalog | Labels may change presentation only. They must not change ViewModel meaning, JSON contracts, arithmetic, or source classification. |
| Report section selection and explicit observation parameters | `tools/report`, report section registry, explicit CLI arguments such as `--outlook-as-of` | view/query selection | Selection belongs to the invocation or presentation layer unless a concrete durable consumer proves a ledger-level policy need. |
| Canonical Daily Cube axes and Layer meaning | `docs/CANONICAL_DAILY_CUBE.md` and current projection contracts | fixed contract | `Day × Account × Layer`, axis meaning, and layer semantics are not configuration candidates. |
| Structured JSON field names, types, nullability, and status vocabulary | section ViewModels/export contracts and `src_next/json.bqn` | machine-interface contract | Contract changes require a concrete consumer and explicit compatibility work; they are not report-label configuration. |
| Privacy and AI context disclosure | no single runtime owner yet; safety/export contracts only | export / consultation policy | Unowned. Default deny. Missing policy means no private context bundle, never broad raw-TSV export. |
| AI proposal and source-write authority | human judgment plus existing editor preview/confirmation/safe-write path | fixed safety boundary | AI has no direct source authority. Configuration must not grant automatic writes, TODO creation, or acceptance of advice. |

## File-level conclusions

### `<base>/config.tsv` is a shared container, not one semantic namespace

Current rows span ledger policy, optional diagnostics, UI preferences, dormant keys, and quarantined legacy contracts. Therefore:

```text
same file
  != same owner
  != same missing-value rule
  != permission for global unknown-key rejection
```

A future key must name its semantic owner and consumer before implementation.

### Source meaning stays near the source

Account role/currency belongs to `accounts.tsv`; cycle boundaries belong to `cycle.tsv`; observed and planned facts belong to journal-like TSV; durable extension metadata may belong to the metadata schema. `config.tsv` is not a catch-all bucket for facts that are inconvenient to model elsewhere.

### Presentation does not redefine accounting

`config/report_labels.tsv`, theme choices, section selection, and formatting preferences may affect human presentation. They must not alter canonical rows, posting authorization, currency arithmetic, Cube coordinates, or structured evidence meaning.

### Engine support is not automatically user configuration

The built-in currency registry is a deliberate code-owned admission seam. Externalizing it requires a separate supported-currency problem, failure contract, compatibility plan, and tests. Inventory completion does not authorize that work.

### Privacy remains deliberately unowned at runtime

The next routed candidate may design a privacy-safe AI context-bundle contract. Until separately selected and defined, there is no private bundle owner and no implicit export permission.

## Rule for future configuration candidates

A future config task must state all of the following before adding a key:

1. concrete consumer and user-visible problem;
2. semantic owner class from this inventory;
3. why existing source metadata, cycle, account metadata, CLI selection, or fixed engine contract is insufficient;
4. missing, explicit-empty, duplicate, unknown, and invalid-value behavior;
5. compatibility and fallback boundary;
6. fixture and negative-test plan;
7. privacy/export effect;
8. explicit non-goals.

Without those answers, keep the candidate outside runtime configuration.

## Verification

This inventory was checked against:

- `config/system_defaults.tsv`;
- `config/default_config.tsv`;
- `config/meta_schema.tsv`;
- `config/report_labels.tsv`;
- `src_next/config.bqn`;
- `CONFIG_KEY_CLASSIFICATION_DECISION-2026-07-05.md`;
- `CONFIG_RESOLUTION_A4_COMPLETION_DECISION-2026-07-05.md`;
- the current configurable-ledger foundation routing map.

No private ledger path, account name, amount, or production row was read or recorded.

## Result

The config ownership inventory row is complete. The next routed candidate is the privacy-safe AI context-bundle contract, but it remains unselected and does not start automatically.
