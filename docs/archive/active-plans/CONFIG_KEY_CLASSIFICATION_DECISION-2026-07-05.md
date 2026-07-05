# Config Key Classification Decision

Status: Phase 0 decision slice / docs-only / runtime unchanged
Date: 2026-07-05
Parent plan: `CONFIG_RESOLUTION_SEMANTICS_PLAN-2026-07-05.md`
Classification item: A4 Partial `config.tsv` semantics

## Decision summary

A4 will not force every current key into one uniform missing-value rule.

For the first typed sparse-override implementation, keys are divided into:

- `defaultable`
- `optional`
- `ui-only`
- `required-explicit` (class retained, but no current key is approved into it yet)

Two additional review states are introduced for keys that are not safe to classify yet:

- `derived-candidate`
- `legacy-contract-review`

These review states are quarantine states, not runtime key classes.
They prevent ambiguous historical keys from silently becoming part of a new resolver contract.

## Why this decision is needed

Current behavior mixes several meanings:

- file-level replacement in `src_next/config.bqn`
- required accessors for some keys
- accessor-level defaults for some keys
- optional empty values for some keys
- shell-only sparse lookups
- entrypoint-specific resolution timing

PR #41 added a dedicated characterization test and fixed the current distinction between:

```text
file-level replacement
        vs
accessor-level fallback
```

This decision classifies the next contract without yet changing runtime behavior.

## Evidence baseline

Inspected current artifacts include:

- `src_next/config.bqn`
- `config/default_config.tsv`
- public sandbox `data/config.tsv`
- relevant config fixtures
- current household-policy, envelope, outlook, projection, and UI consumers
- external live config key presence for compatibility review

External live values are not copied into this decision record.
No external live file is changed by this decision.

## Approved class semantics

### `defaultable`

The repository owns a documented application default.
A ledger may override it locally.

Target missing behavior:

```text
missing local key -> documented application default
explicit empty    -> not automatically treated as missing
```

Unless a key-specific contract says otherwise, explicit empty for a `defaultable` key should be invalid rather than silently falling back.

### `optional`

Absence is a valid state.
The related capability may be disabled, empty, or unavailable.

Target missing behavior:

```text
missing        -> disabled / empty / unavailable
explicit empty -> same only when the key contract explicitly defines empty as disable
```

### `ui-only`

The key controls presentation or interaction and must not alter canonical accounting meaning.

Target ownership:

- UI/presentation layer
- not canonical application-policy meaning

Physical file placement remains a separate follow-up decision.

### `required-explicit`

The ledger/user must state a value.
A default must not silently supply it.

Target missing behavior:

```text
missing -> ERROR
empty   -> ERROR
```

Decision for this slice:

> No current application key is approved as `required-explicit` yet.

This is intentional. A key is not made required merely because the current accessor calls `Required`.

## Quarantine review states

### `derived-candidate`

The key may duplicate information that can be derived from other approved keys.
Do not promote it into typed sparse override until ownership is decided.

### `legacy-contract-review`

The key has historical configuration intent, but current canonical ownership or active consumer need is not clear enough to encode into a new resolver contract.

Do not:

- delete it
- silently default it
- make it newly required
- simplify fixtures around it

until a focused consumer/ownership review is completed.

## Key classification table

| Key | Current behavior | Observed role / consumer | Decision | Reason |
|---|---|---|---|---|
| `HOUSEHOLD_GROUP_LIFE` | `Required` in BQN local-file view; present in default config | household policy, envelope grouping, outlook | `defaultable` | Repository already owns documented default labels; custom ledgers may override. Missing local override should not require copying defaults. |
| `HOUSEHOLD_GROUP_RESERVE` | `Required`; present in default config | household policy and envelope grouping | `defaultable` | Same rationale as life groups; application default exists and is meaningful. |
| `HOUSEHOLD_GROUP_ORDER` | `Required`; present in default config | household policy known-group/order logic | `derived-candidate` | It overlaps information already present in life/reserve group lists. Decide whether order is truly independent before encoding it as a resolver class. |
| `BUDGET_PREFIX` | `Required`; present in default config | historical special-budget-name generalization intent | `legacy-contract-review` | Modern envelope/metadata paths also contain explicit `budget:` prefix fallback logic. Ownership is not clean enough for a new typed contract. |
| `BUDGET_ID_OPENING` | `Required`; present in default config | historical special-budget-account configuration | `legacy-contract-review` | Historical config intent is documented, but current canonical need must be re-proven before promotion. |
| `BUDGET_ID_UNASSIGNED` | `Required`; present in default config | historical special-budget-account configuration | `legacy-contract-review` | Modern unassigned handling also uses account metadata/kind. Do not encode a new missing rule until ownership is confirmed. |
| `BUDGET_ID_SPENT` | `Required`; present in default config | historical special-budget-account configuration | `legacy-contract-review` | Same ownership concern as other special budget IDs. |
| `POLICY_BUDGET_STYLE` | accessor fallback `envelope`; enum validation | household policy availability | `defaultable` | Existing code already treats `envelope` as application default; make that default explicit and centralized rather than accessor-local. |
| `POLICY_RISK_STYLE` | accessor fallback `conservative`; enum validation | outlook safe-daily policy | `defaultable` | Existing code already owns a documented-like default; local ledger may override. |
| `POLICY_INCOME_CADENCE` | missing allowed; warning; empty valid | policy profile / diagnostics | `optional` | Current contract already permits absence and empty. No evidence supports forcing a value. |
| `EXECUTION_PLANNED_PAYMENTS_ENVELOPE` | direct `Get`; empty valid | execution planned-coverage diagnostic | `optional` | Empty/missing disables the diagnostic path; this is a clear optional capability. |
| `THEME` | shell sparse lookup; fallback to `nord` | terminal presentation | `ui-only` | Must not participate in canonical accounting/policy resolution. |
| `FZF_PREVIEW_WINDOW` | shell sparse lookup; fallback to UI default | fzf preview layout | `ui-only` | Pure interaction preference. |

## Important finding: current `Required` is not the future contract

The decision deliberately rejects this inference:

```text
current accessor uses Required
        therefore
future key class = required-explicit
```

That would preserve an implementation accident as architecture.

In particular:

- household group keys have repository defaults and are good sparse-override candidates
- special `BUDGET_*` keys carry historical meaning but need ownership review

The new contract must be based on meaning and ownership, not only current accessor shape.

## Important finding: no current `required-explicit` key yet

This is not a missing decision.

A `required-explicit` key should exist only when:

1. a repository default would be unsafe or misleading,
2. the ledger-specific choice is semantically necessary,
3. absence must fail closed,
4. a canonical consumer demonstrably depends on the explicit choice.

No currently inspected application key met all four conditions strongly enough for approval in this slice.

Future keys may use the class.

## `HOUSEHOLD_GROUP_ORDER` decision hold

Current config stores:

```text
HOUSEHOLD_GROUP_LIFE
HOUSEHOLD_GROUP_RESERVE
HOUSEHOLD_GROUP_ORDER
```

The order key may be:

- genuinely independent presentation/policy order, or
- derivable from the ordered life list plus reserve list.

Before a resolver change, decide one of:

```text
A. keep independent and classify explicitly
B. derive from LIFE + RESERVE
C. replace with a more general ordered-group contract
```

Until then it remains `derived-candidate` and current runtime behavior stays unchanged.

## `BUDGET_*` ownership hold

Historical generalization docs record that special budget account names were moved into config.

However, inspected modern code also shows:

- explicit `budget:` prefix fallback in envelope/account-role paths
- metadata-driven envelope and unassigned handling
- current config accessors still marking all special budget keys required

This is enough to show mixed ownership, but not enough to safely choose a new missing-value class.

Therefore these keys stay in `legacy-contract-review`.

A later focused review should answer:

1. Which current canonical modules call the four accessors?
2. Which paths still depend on literal `budget:` fallback?
3. Which special IDs are still semantically necessary after metadata migration?
4. Can any key be removed, derived, or moved to account metadata?

No runtime cleanup is authorized by this document.

## Unknown-key policy

Decision for the first application-resolver slice:

> Do not introduce global unknown-key errors yet.

Reason:

The same `<base>/config.tsv` currently carries keys owned by different consumers, including UI-only keys.
A BQN application resolver cannot safely treat every non-application key as an error without either:

- knowing UI keys it should not own, or
- first splitting/namespacing the file.

Therefore first-slice behavior should be:

```text
known application key -> validate by approved class
other key             -> preserve/ignore at application resolver boundary
```

A stricter unknown-key policy is deferred to the UI ownership / namespace decision.

This avoids making BQN the accidental owner of presentation keys.

## Duplicate-key policy

Target decision:

> Duplicate keys should fail visibly in the future effective application config path.

Reason:

Current first-match behavior is ambiguous and can hide edits.

Implementation note:

- exact error shape is not decided here
- no runtime duplicate detection is added by this docs-only slice
- tests should precede behavior change

## Missing versus explicit empty

The future resolver must preserve this distinction.

### Defaultable

```text
missing local key -> use documented default
explicit empty    -> ERROR unless key contract explicitly allows empty
```

### Optional

```text
missing        -> absent / disabled
explicit empty -> disabled only where documented
```

### UI-only

Owned by UI contract, not application resolver.

### Quarantine states

No new rule until promoted.

## First implementation eligibility

### Eligible for typed sparse-override implementation

```text
HOUSEHOLD_GROUP_LIFE
HOUSEHOLD_GROUP_RESERVE
POLICY_BUDGET_STYLE
POLICY_RISK_STYLE
POLICY_INCOME_CADENCE
EXECUTION_PLANNED_PAYMENTS_ENVELOPE
```

### Not eligible yet

```text
HOUSEHOLD_GROUP_ORDER
BUDGET_PREFIX
BUDGET_ID_OPENING
BUDGET_ID_UNASSIGNED
BUDGET_ID_SPENT
THEME
FZF_PREVIEW_WINDOW
```

Reasons:

- `HOUSEHOLD_GROUP_ORDER`: derivation decision pending
- `BUDGET_*`: ownership review pending
- UI keys: separate owner

## Compatibility decision

The first resolver implementation must preserve these boundaries:

- existing full-ish public sandbox config remains valid
- existing full-ish external live config remains valid without rewrite
- external live config is never automatically edited
- extra UI-owned keys in a shared config file do not cause application-resolution failure
- no fixture simplification is bundled into the first resolver behavior change

## Next approved candidate slice

The next candidate is intentionally narrow:

1. extend dedicated config tests for the six eligible application keys
2. characterize missing vs explicit empty
3. add negative tests before runtime change
4. only then implement effective config resolution for eligible keys

Not part of that slice:

- `BUDGET_*` cleanup
- group-order redesign
- UI config split
- live config migration
- fixture mass cleanup

## Review status

This decision is `active`.

It advances A4 Phase 0 but does not mark A4 resolved.
A4 remains open until resolver behavior is implemented and reviewed, or the plan is revised/rejected.
