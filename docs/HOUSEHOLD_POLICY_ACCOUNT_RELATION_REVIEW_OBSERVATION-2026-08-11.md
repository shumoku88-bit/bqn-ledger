# Household policy Account relation review observation — 2026-08-11

## Context

This review follows the merged Household section refactor in PR #665. Section ownership and multiline lexical state are already separated. The question here is narrower: how canonical `household.toml` Account references relate to the admitted `accounts.journal` Account axis.

The production owner remains `src/ledger/household_policy_admission.bqn`.

## Previous shape

The owner had one scalar helper:

```text
Account key
  -> IndexOf
  -> known / role checks
  -> boolean
```

Most callers then immediately performed `IndexOf` on the same key again to obtain the coordinate for publication.

This occurred across:

- Cycle income Account validation;
- Budget unassigned Accounts;
- Envelope allocation Account;
- retained optional `plan-destination-accounts` syntax is accepted for physical compatibility but is not projected as semantic policy;
- Daily Target Asset Accounts;
- all five Account-policy axes.

The dense Account-policy result then introduced another traversal: for each Account, each `AxisValues` call rescanned all temporary `axisRows` to find the matching label.

## Characterization before production change

A focused forged Account carrier keeps the same admitted shape while making two adjacent Expense-policy references differ:

- `expenses:food` remains known but its role is changed to Asset;
- `expenses:transport` is replaced on the Account axis and is therefore unknown.

The established diagnostic order is key-major:

```text
household_account_role_invalid
household_account_unknown
```

not diagnostic-kind-major.

The test also protects fail-closed dense Account-policy publication. Characterization-only CI #2683 was SUCCESS.

## Retained Account relation

The scalar `ValidateAccount` plus repeated `IndexOf` path is replaced by one local vector relation:

```text
Account key cells
  -> Account coordinate via `⊐`
  -> known mask
  -> aligned Account role cells
  -> role-invalid mask
  -> key-ordered diagnostic cells
  -> valid mask + same coordinates
```

The exact same coordinates now feed publication.

Unknown and role diagnostics are constructed inside one diagnostic cell per source key before flattening. This preserves key order even when diagnostic kinds differ.

The top-level private `IndexOf` helper became unused and was removed.

## Call-site effects

### Cycle

The income Account needs validation side effects but no retained numeric coordinate. The old unused `incomeIndex` / `incomeValid` staging disappears.

### Budget unassigned Accounts

The entire key vector is classified once. Valid coordinates are selected directly from the returned mask rather than appended after a second lookup.

### Envelope Accounts

Allocation and destination key cells each receive one Account relation. Allocation publication reuses its scalar coordinate; destination publication selects valid coordinates from its vector relation.

### Daily Target

The selected Asset Account coordinate comes from the same scalar relation that proves its role.

### Account-policy axes

Each member array is classified once. Valid member coordinates become the sparse `axisRows` relation without another lookup.

## Dense Account-policy axis

The previous `AxisValues` implementation iterated every Account and rescanned all `axisRows` for each Account/section pair.

The retained form is:

```text
selected sparse rows for one policy axis
  -> sparse Account coordinates
  -> duplicate-coordinate check
  -> sparse-coordinate `⊐` against canonical Account axis
  -> Select labels with one appended empty fill cell
```

Thus the admitted Account order remains the dense output axis, while missing policy members receive `""` through the absent Index-Of coordinate.

Duplicate-coordinate failure remains fail closed. In an invalid source the derived dense axis is not published; the public result receives the existing empty Account-aligned axis.

## Evidence

- CI #2683 SUCCESS: characterization-only head;
- CI #2684 SUCCESS: vector Account relation and dense-axis coordinate publication, including full `tools/check.sh` and coverage.

## Deliberate non-change

This change does not alter:

- Account identity/type ownership in `accounts.journal`;
- section parsing or multiline TOML logic;
- Household section cardinality/key rules;
- Envelope or Daily Target semantics;
- Budget-policy ownership;
- public Account-policy field names or Account order;
- diagnostic messages or fail-closed behavior;
- canonical source or writer authority.

The purpose is not to introduce a generic join abstraction. `AccountRelations` is local vocabulary for the concrete Household-to-Account relation and returns exactly the coordinate/mask evidence this owner needs.

## Review conclusion

The semantic improvement is:

```text
validate key
then rediscover its coordinate
then rescan rows per Account

->

classify key cells once onto the Account axis
reuse coordinates for validation and publication
densify sparse policy coordinates directly onto the canonical Account axis
```

Together with PR #665, the Household owner now distinguishes three different structures instead of treating them all as procedural state:

1. genuine sequential lexical state for multiline TOML arrays;
2. logical row-to-section coordinates;
3. semantic Account key-to-Account coordinates.