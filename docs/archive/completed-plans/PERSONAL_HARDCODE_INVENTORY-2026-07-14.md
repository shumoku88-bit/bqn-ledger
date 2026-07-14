# Personal hardcode inventory — 2026-07-14

Status: completed docs-only inventory
Owner: configuration / presentation / profile boundaries
Canonical: no; current behavior remains owned by the referenced runtime and source contracts
Exit: archived completion record; each externalization requires a separately selected finite implementation slice

## Purpose

Record which current literals are user/profile choices, which are deliberate fixed contracts, and which must remain quarantined until a concrete consumer exists.

This inventory follows the completed config ownership inventory. It does not add a config key, module loader, plugin framework, runtime behavior, source schema, report output, or production-data change.

The immediate product direction is:

```text
stable accounting core
  + ledger-owned source/configuration
  + optional policy/profile modules
  + presentation catalogs
```

The inventory deliberately does not assume that every literal should become a config key.

## Classification

| Class | Meaning |
|---|---|
| `externalize-next` | A user/profile or presentation choice with a concrete current consumer. Suitable for a small future slice. |
| `profile-bound` | A valid specialized module value that should not leak into the general core. Generalization requires an explicit profile/composition boundary first. |
| `keep-fixed` | A protocol, accounting invariant, machine contract, or closed semantic vocabulary. |
| `quarantine` | Mixed legacy ownership or insufficient evidence. Do not migrate merely because a literal exists. |
| `fixture/example` | Synthetic evidence or documentation example, not runtime personalization. |

## Findings

### A. Household defaults in `config/default_config.tsv`

Current literals:

```text
HOUSEHOLD_GROUP_LIFE=daily,flex
HOUSEHOLD_GROUP_RESERVE=reserve
HOUSEHOLD_GROUP_ORDER=daily,flex,reserve
POLICY_BUDGET_STYLE=envelope
POLICY_RISK_STYLE=conservative
```

Classification: `externalize-next`, with separate ownership decisions per key.

Reason:

- `daily`, `flex`, and `reserve` describe the current household policy vocabulary, not universal accounting truth.
- `envelope` is a valid budget style but must not be the invisible worldview of every new ledger.
- `conservative` is a derived-view choice and should not silently become every user's policy.
- repository defaults currently make a missing local choice look like an intentional household choice.

Required future decisions:

- whether each key is required in ledger-local `config.tsv`, supplied by an explicit profile, or has a genuinely neutral repository fallback;
- missing, explicit-empty, duplicate, unknown, and invalid-value behavior;
- migration behavior for existing ledgers that currently rely on repository fallback;
- fixture coverage for an envelope ledger and a non-envelope ledger.

Do not externalize all five keys in one broad migration.

### B. Presentation text still embedded in report modules

`config/report_labels.tsv` already owns much human-facing text, but some `src_next/outlook.bqn` presentation remains literal, including:

```text
〜
envelope | remaining | /day
─────────────────────────────
```

Classification: `externalize-next`.

Reason:

- these strings alter presentation only;
- a label catalog already exists;
- moving them does not require changing arithmetic, ViewModel fields, JSON, source meaning, or policy selection.

This is the smallest recommended first implementation slice after this inventory. It should add focused missing-label failure tests and preserve byte-for-byte current Japanese output through the default catalog.

### C. Israel trip identity and currency tuple

Current specialized runtime literals include:

- `trip_id = israel-2026` in `src_next/friend_travel_source_event.bqn`;
- `trip_id = israel-2026` in `src_next/travel_exchange_event.bqn`;
- friend-event original currency fixed to `ILS`;
- exchange direction fixed to `JPY -> ILS`;
- JPY zero-fraction and ILS two-fraction constraints in the Israel exchange module.

Classification: `profile-bound`.

Reason:

- these values are correct for the completed Israel reference profile;
- they are not general household-ledger core policy;
- simply turning them into free config strings would weaken the closed validation contract;
- the travel modules are currently useful because they are narrow and fail closed.

Future generalization should first introduce one explicit composition/profile boundary, for example:

```text
Israel reference profile
  -> trip identity
  -> admitted payment paths
  -> source and target currency policy
  -> friend pending-event policy
  -> exchange-event policy
```

No dynamic plugin discovery, arbitrary module path loading, or generic travel DSL is justified yet. Keep the current Israel modules unchanged until a second concrete travel profile proves the shared boundary.

### D. Closed travel-event vocabulary

Current literals include:

```text
payer=friend
status=pending
```

Classification: `keep-fixed` inside the current friend-pending-event consumer.

These are not personal preferences. They define what the module means. A different payer or lifecycle should be a different explicitly designed consumer rather than an unchecked string option.

The fixed nine-column friend-event row and ten-column exchange-event row are also protocol contracts, not user configuration.

### E. Account namespace and role fallbacks

Current examples include:

- `income:` checks in `src_next/outlook.bqn`;
- `expenses:` prefix fallback diagnostics in `src_next/household_policy.bqn`;
- `liabilities:` checks for next-cycle obligations;
- `BUDGET_PREFIX` and `BUDGET_ID_*` compatibility accessors.

Classification: `quarantine`.

Reason:

- some paths are compatibility behavior, while current account metadata is the preferred semantic owner;
- changing them could alter classification, balances, obligation discovery, or legacy fixtures;
- the completed config ownership inventory already classifies budget prefix/IDs and group ordering as unresolved or legacy-contract review.

Do not convert these literals into user settings before a focused consumer demonstrates that account metadata cannot own the meaning.

### F. Spend-class and account-role vocabulary

Current literals include:

```text
expense
income
liquid
variable
fixed
```

Classification: mostly `keep-fixed` semantic vocabulary.

These terms participate in validated account metadata, Posting IR interpretation, or report contracts. Display labels may be translated, but the underlying machine vocabulary should not vary per user without a schema-versioned contract change.

### G. Currency registry

`config/currencies.tsv` and `src_next/currency_setup.bqn` currently own built-in admitted currency codes and lexical precision.

Classification: `keep-fixed` engine-admission seam for now.

The registry is already centralized, but that does not make it arbitrary ledger-local configuration. Adding a supported currency is a repository capability change with exact-decimal, fixture, editor, and report implications.

`DEFAULT_CURRENCY` remains ledger-local initial view selection and must never supply missing source currency.

### H. Report labels and units

`config/report_labels.tsv` contains a mixed Japanese/English default presentation catalog, including yen-specific calculator phrases and units.

Classification:

- catalog text itself: `externalize-next` through later presentation-profile work;
- structured JSON field names and status vocabulary: `keep-fixed` machine contracts;
- yen-specific calculator wording: externalize only with the concrete calculator consumer and selected-currency semantics, not by blind translation.

A future language/profile design should prefer an explicit catalog selection or injected catalog root over sprinkling locale conditionals through BQN modules.

### I. Fixtures and examples

Paths such as:

- `fixtures/household-moko/`;
- `fixtures/generalization-moko/`;
- `fixtures/household-monthly-salary/`;
- `fixtures/currency-usd-single/`;
- Israel usage documentation and synthetic checks;

are classified as `fixture/example` unless a literal is also present in current runtime code.

Specific fixtures are valuable. They should remain visibly specific rather than being scrubbed into one vague universal fixture.

## Module boundary direction

The first safe decomposition target is not a general plugin system. Use explicit composition with narrow contracts:

```text
accounting core
  Posting IR
  exact arithmetic
  Cube / TBDS
  source validation

ledger policy
  budget style
  risk style
  household grouping

reference profiles
  Israel travel capture
  future second concrete profile

presentation
  report label catalog
  section/view selection
```

A module may be selectable only when:

1. at least two concrete consumers prove the variation;
2. both implementations accept the same typed input contract;
3. both return the same typed result contract;
4. unknown module selection fails closed;
5. the selection does not grant source-write or arbitrary code-loading authority.

Until then, an explicit composition root is preferable to dynamic discovery.

## Ordered follow-up candidates

This is an order of consideration, not automatic authorization.

1. **Outlook presentation-literal extraction**
   - move the remaining table headers, separator text, and date-range separator into `config/report_labels.tsv`;
   - preserve current output exactly;
   - no arithmetic, ViewModel, JSON, source, or policy change.
2. **Household repository-default decision, one key family at a time**
   - begin with `POLICY_BUDGET_STYLE` or household group labels only after choosing compatibility behavior;
   - prove both envelope and non-envelope fixtures.
3. **Presentation catalog/profile boundary**
   - only after more than one complete catalog consumer exists;
   - no locale conditionals in accounting modules.
4. **Travel profile composition boundary**
   - only when a second concrete trip/profile exists;
   - keep the Israel profile as a reference implementation.
5. **Policy-module selection**
   - only after two implementations share a stable typed contract;
   - no dynamic arbitrary module loading.

## Explicit non-goals

- no config key or schema addition;
- no runtime or report output change;
- no source TSV or production-data read/write;
- no plugin manager, package system, module-path setting, dependency injection framework, or arbitrary code loading;
- no broad removal of account-prefix compatibility;
- no user-editable Cube axes, Layer meaning, role vocabulary, machine JSON keys, or exact-arithmetic rules;
- no Israel writer finalization, strict-source Steps 2–5, M4, AI context bundle, or Observatory work.

## Verification basis

This inventory was checked against current main owners including:

- `config/default_config.tsv`;
- `config/report_labels.tsv`;
- `src_next/config.bqn`;
- `src_next/outlook.bqn`;
- `src_next/household_policy.bqn`;
- `src_next/friend_travel_source_event.bqn`;
- `src_next/travel_exchange_event.bqn`;
- `src_next/currency_setup.bqn`;
- `docs/archive/completed-plans/CONFIG_OWNERSHIP_INVENTORY-2026-07-14.md`;
- `docs/archive/active-plans/CONFIGURABLE_AI_ASSISTED_LEDGER_FOUNDATION-2026-07-13.md`.

No private ledger path, private account name, private amount, or production row was read or recorded.

## Result

The personal-hardcode inventory is complete.

The smallest next implementation candidate is the remaining Outlook presentation-literal extraction. It is not selected by this inventory and must enter as a separate finite slice.