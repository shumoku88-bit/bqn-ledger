# Config Key Classification Decision

Status: Phase 0 decision slice / docs-only / runtime unchanged
Date: 2026-07-05
Parent plan: `CONFIG_RESOLUTION_SEMANTICS_PLAN-2026-07-05.md`
Classification item: A4 Partial `config.tsv` semantics

## Decision

A4 will not infer future key meaning from the current accessor shape.

In particular:

```text
current accessor uses Required
        !=
future key class is required-explicit
```

The first typed sparse-override contract uses four runtime classes:

- `defaultable`
- `optional`
- `ui-only`
- `required-explicit`

Two quarantine states are used where ownership is not clear enough:

- `derived-candidate`
- `legacy-contract-review`

Quarantine states are not runtime classes. They prevent ambiguous keys from silently entering a new resolver contract.

PR #41 already characterizes the current distinction between file-level replacement and accessor-level fallback. This document chooses key meaning only; it changes no runtime behavior.

## Class semantics

### `defaultable`

The repository owns a documented application default and a ledger may override it.

```text
missing local key -> documented default
explicit empty    -> ERROR unless explicitly allowed
```

### `optional`

Absence is valid and may disable a capability.

```text
missing        -> absent / disabled / unavailable
explicit empty -> disabled only where documented
```

### `ui-only`

Presentation or interaction preference. It must not change canonical accounting meaning.

### `required-explicit`

The ledger must state the value because a repository default would be unsafe or misleading.

```text
missing -> ERROR
empty   -> ERROR
```

**No current application key is approved into this class yet.**

### `derived-candidate`

The key may duplicate information derivable from other keys. Hold before resolver implementation.

### `legacy-contract-review`

The key has historical configuration intent but current canonical ownership is not clear enough to encode into a new missing-value rule.

Do not delete, newly default, newly require, or mass-clean fixtures around these keys before focused review.

## Key classification

| Key | Current behavior / observed role | Decision | Reason |
|---|---|---|---|
| `HOUSEHOLD_GROUP_LIFE` | `Required`; default exists; used by household policy, envelope grouping, outlook | `defaultable` | Repository already owns default labels; local ledgers may override. |
| `HOUSEHOLD_GROUP_RESERVE` | `Required`; default exists; used by household policy/envelopes | `defaultable` | Same rationale as life groups. |
| `HOUSEHOLD_GROUP_ORDER` | `Required`; used by known-group/order logic | `derived-candidate` | May overlap the ordered LIFE + RESERVE lists. Decide whether it is truly independent. |
| `BUDGET_PREFIX` | `Required`; historical special-budget-name config | `legacy-contract-review` | Modern paths also contain literal `budget:` fallback logic. Ownership is mixed. |
| `BUDGET_ID_OPENING` | `Required`; historical special budget ID | `legacy-contract-review` | Current canonical need must be re-proven before promotion. |
| `BUDGET_ID_UNASSIGNED` | `Required`; historical special budget ID | `legacy-contract-review` | Modern unassigned handling also uses metadata/kind. |
| `BUDGET_ID_SPENT` | `Required`; historical special budget ID | `legacy-contract-review` | Same ownership concern as other special IDs. |
| `POLICY_BUDGET_STYLE` | fallback `envelope`; enum validation; household policy | `defaultable` | Existing code already owns the application default. |
| `POLICY_RISK_STYLE` | fallback `conservative`; enum validation; outlook | `defaultable` | Existing code already owns the application default. |
| `POLICY_INCOME_CADENCE` | missing/empty allowed | `optional` | No evidence supports forcing a value. |
| `EXECUTION_PLANNED_PAYMENTS_ENVELOPE` | empty disables planned-coverage diagnostic | `optional` | Clear optional capability. |
| `THEME` | shell sparse lookup with UI fallback | `ui-only` | Terminal presentation only. |
| `FZF_PREVIEW_WINDOW` | shell sparse lookup with UI fallback | `ui-only` | Interaction layout only. |

## Key findings

### 1. No current `required-explicit` key

This is intentional.

A key should enter `required-explicit` only when all are true:

1. a repository default would be unsafe or misleading,
2. the ledger-specific choice is semantically necessary,
3. absence must fail closed,
4. a canonical consumer demonstrably depends on the explicit choice.

No inspected current application key met all four strongly enough.

### 2. `HOUSEHOLD_GROUP_ORDER` is held

Current config stores LIFE, RESERVE, and ORDER separately.
Before resolver change, decide whether ORDER is:

- independent,
- derived from LIFE + RESERVE, or
- replaced by a more general ordered-group contract.

Current runtime behavior stays unchanged meanwhile.

### 3. `BUDGET_*` is held

Historical generalization docs say special budget account names moved into config.
Inspected modern code also shows metadata-driven handling and literal `budget:` fallback paths.

That is enough to show mixed ownership, not enough to safely choose a new class.

Focused follow-up questions:

1. Which canonical modules still call the four accessors?
2. Which paths still depend on literal `budget:` fallback?
3. Which special IDs remain necessary after metadata migration?
4. Can any key be removed, derived, or moved to account metadata?

No cleanup is authorized here.

## Unknown-key policy

For the first application-resolver slice:

> Do not introduce global unknown-key errors yet.

The shared `<base>/config.tsv` currently carries keys owned by different consumers, including UI-only keys. A BQN application resolver must not become the accidental owner of presentation settings.

First-slice target:

```text
known application key -> validate by approved class
other key             -> ignore/preserve at application resolver boundary
```

A stricter policy waits for the UI ownership or namespace decision.

## Duplicate-key policy

Future effective application config should fail visibly on duplicate keys.

Current first-match behavior is ambiguous and can hide edits.
This document adds no runtime duplicate detection; tests must precede behavior change.

## First implementation eligibility

Eligible:

```text
HOUSEHOLD_GROUP_LIFE
HOUSEHOLD_GROUP_RESERVE
POLICY_BUDGET_STYLE
POLICY_RISK_STYLE
POLICY_INCOME_CADENCE
EXECUTION_PLANNED_PAYMENTS_ENVELOPE
```

Held out:

```text
HOUSEHOLD_GROUP_ORDER
BUDGET_PREFIX
BUDGET_ID_OPENING
BUDGET_ID_UNASSIGNED
BUDGET_ID_SPENT
THEME
FZF_PREVIEW_WINDOW
```

## Compatibility boundary

The first resolver implementation must preserve:

- existing full-ish public sandbox config
- existing full-ish external live config without rewrite
- no automatic live-config editing
- extra UI-owned keys in the shared file must not break application resolution
- no fixture mass cleanup in the resolver behavior change

External live values are not copied into this decision record.

## Next candidate slice

1. extend dedicated config tests for the six eligible keys
2. characterize missing vs explicit empty
3. add negative tests before runtime change
4. only then implement effective resolution for eligible keys

Not included:

- `BUDGET_*` cleanup
- group-order redesign
- UI config split
- live migration
- fixture mass cleanup

A4 remains open until resolver behavior is implemented and reviewed, or this direction is revised/rejected.
