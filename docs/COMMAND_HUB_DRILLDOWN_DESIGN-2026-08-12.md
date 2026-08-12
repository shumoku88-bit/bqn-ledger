# Command Hub drill-down design — 2026-08-12

## Status

Design only. This document does not authorize a runtime or selector rewrite by itself.

The Command Hub should be reorganized independently from the BQN-native production review. The two tracks may observe the same files, but UI navigation must not become a reason to move accounting, admission, writer, or report semantics into shell selectors.

## Problem

The current interactive top menu mixes several different kinds of choice at one level:

```text
Record / Journal
Plans
Budget
Accounts
Issues
Reports
Inspect / Operations
```

This exposes implementation/domain partitions before the user has expressed the more basic intent: change Household evidence, read semantic results, or work directly with sources/system tooling.

It also causes read-only report actions to appear inside editor-oriented domains, for example Account Balances under Accounts, Envelope & Backing under Budget, and the Issues report under Issues. Raw canonical-source editing is hidden under Operations even though it is a qualitatively different authority boundary from structured Editor writes.

## Primary navigation decision

Use three top-level entrances, with the first two as the ordinary daily paths:

```text
BQN Ledger

  Editor
  Reports
  Source & System
  Exit
```

The first question is therefore not which source/domain object exists, but which kind of interaction is intended.

### 1. Editor

`Editor` means writer-backed or editor-owned interaction with Household evidence. It must not contain semantic reports merely because a report shares the same domain noun.

Proposed drill-down:

```text
Editor
  Journal
    Expense
    Income
    Transfer / move
    Multi-posting transaction
    Reverse with compensating transaction
    History / select transaction

  Plans
    Browse open Plans
    Browse overdue Plans
    Browse upcoming Plans
    Related evidence
    Add Plan
    Edit Plan
    Finish / actualize Plan
    Retry Budget sync

  Budget
    Add / move Budget

  Accounts
    List / select Accounts
    Add Account

  Issues
    List / select open Issues
    Add Issue
    Close Issue

  Back
```

Read-only list/select surfaces may stay inside an Editor domain when they are the natural way to choose the object to edit. General semantic reports do not.

### 2. Reports

`Reports` is read-only semantic presentation. It should drill down from report group to retained report, while the existing Report catalog remains the authority for keys, labels, supported surfaces, and owners.

Do not create a second report catalog in `tools/bl`.

The current catalog already owns a `category` axis. The initial design should reuse that relation rather than hard-code a competing classification. Human-facing labels may be friendlier than the internal category tokens:

```text
Reports
  Household
    Envelope & Backing
    Daily Target

  Accounting
    Account Balances
    Balance Sheet
    Profit and Loss
    Current-cycle Accounts
    Cycle Comparison
    Monthly Accounts
    Daily Flow

  Activity
    Recent Journal
    Planned Payments
    Issues

  All reports
  Sequential preview
  Back
```

`Activity` is only a display label for the current catalog's `operations` category. It does not rename or redefine the report category relation.

If the seven-item Accounting group later proves too broad in actual use, a second presentation level can be considered then. Do not invent that extra taxonomy before observing use.

### 3. Source & System

This is deliberately separate from `Editor`.

Structured Editor actions pass through the existing writer/admission/safe-publication path. Opening a canonical source in `$EDITOR` gives the human direct access to source bytes and therefore must not masquerade as the same operation.

Proposed drill-down:

```text
Source & System
  Open canonical source
    accounts.journal
    actual.journal
    plan.journal
    budget.journal
    budget.toml
    household.toml
    report.toml
    issues.tsv

  Household check
  Ledger / provenance inspection
  Dependency and source diagnosis
  Export canonical Journals to hledger
  Compact report summary
  Exact compact-key query (advanced)
  Repository development suite
  Back
```

The eight-file list remains owned by the canonical Household source boundary. Navigation may present those names, but it must not gain authority to discover alternate basenames or redirect writers.

## Navigation laws

1. Interactive hierarchy is a selector concern, not an accounting or writer owner.
2. Direct CLI commands remain stable unless there is an independent reason to change them. Interactive restructuring must not break scriptable entry points.
3. Editor and Reports do not duplicate each other's leaves merely because they share a domain noun.
4. A read-only selection that is necessary to choose an edit target may live in Editor; a semantic report belongs in Reports.
5. Raw source opening is visually and structurally separated from structured Editor writes.
6. Report keys and labels remain sourced from the retained Report catalog. Grouping should consume catalog metadata rather than copy the twelve keys into a second list.
7. Canonical source names remain sourced from the canonical Household source owner; the Hub must not create alternate source policy.
8. `fzf`, `gum`, and plain selectors present the same navigation relation. Selector-specific behavior must not become feature ownership.
9. Back navigation is explicit at every drill-down boundary, and returning from a child command returns to the immediately containing menu.
10. The Hub should optimize daily recognition and locality, not expose the repository architecture as its menu tree.

## Existing actions that move under the new hierarchy

The current mixed domain/report entries would be separated as follows:

- `Accounts > Account Balances report` moves to `Reports > Accounting > Account Balances`.
- `Budget > Envelope & Backing report` moves to `Reports > Household > Envelope & Backing`.
- `Issues > Issues report` moves to `Reports > Activity > Issues`.
- `Record > Journal history` may remain under `Editor > Journal` because it is useful as an edit/reversal selection surface; `Recent Journal` remains a Report.
- `Operations > Edit canonical source` moves to the first-class `Source & System > Open canonical source` path.
- check/inspect/doctor/export/query/development commands remain in `Source & System` rather than competing with daily Editor/Reports choices.

## Deliberate non-goals

This design does not yet:

- rewrite `tools/bl`;
- change `tools/main-ui.sh`;
- add a new TUI framework;
- change Report catalog semantics;
- change writer authority;
- move source admission into shell;
- collapse BQN-native Phase 6 review into UI work;
- decide keyboard accelerators, colors, icons, preview geometry, or selector-specific decoration.

Those should follow only after the information architecture itself is accepted.

## Implementation observation to preserve

The current Hub already states the correct architectural boundary: it owns navigation, selection, and presentation while accounting, admission, and publication remain in their existing owners. The drill-down rewrite should preserve that statement and reduce mixed responsibility rather than replacing it with a new command framework.

## Next design check

Before implementation, walk through at least these ordinary tasks against the hierarchy:

1. record a normal expense;
2. actualize a Plan and replenish the next Plan;
3. close an Issue;
4. inspect upcoming obligations;
5. inspect balances and Envelope state;
6. open `actual.journal` directly for deliberate source inspection;
7. run Household admission diagnostics.

If any of these require bouncing between unrelated branches of the tree, revise the hierarchy before writing shell code.
