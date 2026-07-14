# POLICY_BUDGET_STYLE compatibility audit — 2026-07-14

Status: completed compatibility audit and enforcement slice
Owner: ledger policy / public fixture and onboarding configuration
Parent decision: `POLICY_BUDGET_STYLE_EXPLICIT_CHOICE_DECISION-2026-07-14.md`
Runtime fallback: unchanged; missing-key fail-closed migration remains separately unselected

## Purpose

Verify which public ledger-like roots explicitly choose `POLICY_BUDGET_STYLE=envelope` or `POLICY_BUDGET_STYLE=none`, distinguish ordinary examples from intentional missing/empty compatibility fixtures, and prevent new ambiguous committed configurations.

No private or live configuration was read or edited.

## Initial inventory

A repository-owned CI inventory scanned `data/` and every top-level fixture directory containing ledger-like TSV/configuration files.

```text
ledger-like roots: 78
explicit envelope/none: 11
config.tsv present but key missing: 9
config.tsv present with empty value: 1
config.tsv absent: 57
```

The absence count included the Quick Start demo and many old technical fixtures that intentionally inherit the repository fallback by having no local `config.tsv`.

## Classification and changes

### First-class public example

`fixtures/demo/` is the README Quick Start and contains real envelope allocations and envelope account metadata. It now has a complete public `config.tsv` with:

```text
POLICY_BUDGET_STYLE=envelope
```

The rest of its policy values preserve the former repository fallback. A focused smoke check runs its snapshot command.

### Ordinary config-bearing fixtures normalized

The following fixtures had a local `config.tsv` but relied on the missing-key `envelope` fallback. They now state `envelope` explicitly, preserving current behavior:

- `fixtures/currency-m3-balances/`
- `fixtures/editor-currency-m2/`
- `fixtures/historical-cycle/`
- `fixtures/src-next-config-effective-life-empty/`
- `fixtures/src-next-config-effective-life-override/`
- `fixtures/src-next-config-effective-reserve-empty/`
- `fixtures/src-next-config-effective-reserve-override/`

The group empty/override fixtures still test their named group-key behavior; the unrelated budget-style choice is no longer implicit.

### Intentional compatibility and negative fixtures

Exactly three committed configs retain non-explicit states:

| Path | Expected state | Reason |
|---|---|---|
| `fixtures/src-next-config-eligible-missing/config.tsv` | missing | proves missing-key presence and typed fallback behavior |
| `fixtures/src-next-household-mapping-policy/config.tsv` | missing | proves partial local config and compatibility fallback for policy accessors |
| `fixtures/src-next-config-eligible-empty/config.tsv` | explicit empty | proves the current empty-value error contract |

The enforcement check verifies both the paths and their expected states, so an exception cannot silently broaden or become stale.

### Legacy technical roots without config.tsv

After adding the demo config, 56 existing technical fixture roots still have no local `config.tsv`.

They were not mass-populated because creating a local config changes file-selection and effective-resolution behavior, not merely one label. These roots remain legacy repository-fallback coverage until a concrete fixture-specific migration is selected.

This is not permission for new first-class examples to omit configuration.

## Enforcement

`checks/audit-budget-style-explicit.sh` now:

1. scans every committed `data/**/config.tsv` and `fixtures/**/config.tsv`;
2. requires exactly one valid `envelope` or `none` value except for the three named fixtures;
3. verifies the expected missing/empty state of every exception;
4. requires an explicit choice for the current first-class public ledger/profile/example list;
5. fails on duplicate, empty, unknown, newly missing, or stale exception states;
6. runs the Quick Start demo snapshot as a compatibility smoke check.

Current passing classification:

```text
explicit configs: 19
intentional exceptions: 3
legacy ledger-like roots without config.tsv: 56
```

## Onboarding rule

A new first-class ledger, profile, Quick Start example, or generated setup must include one of:

```text
POLICY_BUDGET_STYLE=envelope
POLICY_BUDGET_STYLE=none
```

`missing` is compatibility behavior, not a valid new choice.

## Non-goals

- no removal of the current runtime fallback;
- no change to accounting arithmetic, report meaning, ViewModels, JSON, or source schemas;
- no automatic conversion between envelope and non-envelope source data;
- no mass creation of config files for old technical fixtures;
- no private/live configuration migration;
- no plugin or profile-loading framework.

## Result

The public compatibility audit is complete. The repository now has an enforceable boundary for explicit budget-style choices while preserving the narrow fixtures that prove the temporary compatibility contract.
