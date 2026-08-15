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

The task walkthrough changed one part of the initial design: general-purpose `Browse` / `List` leaves do not belong here. A list that exists only to choose a mutation target should appear after the mutation has been selected.

Proposed drill-down:

```text
Editor
  Journal
    Expense
    Income
    Transfer / move
    Multi-posting transaction
    Reverse
      -> select transaction

  Plans
    Add Plan
    Edit Plan
      -> select open Plan
    Finish / actualize / replenish
      -> select open Plan
    Related evidence for a Plan
      -> select Plan

  Budget
    Add / move Budget

  Accounts
    Add Account

  Issues
    Add Issue
    Close Issue
      -> select open Issue

  Back
```

This keeps the ordinary distinction crisp:

```text
want to change evidence  -> Editor
want to inspect meaning  -> Reports
```

Selection rows may still be produced by current editor list commands internally. The navigation rule is about where that read appears in the user's task, not about deleting useful read-only command capabilities.

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
4. General read-only inspection belongs in Reports. A read-only selector needed to choose a mutation target is subordinate to that Editor action rather than exposed as an Editor browse leaf.
5. Raw source opening is visually and structurally separated from structured Editor writes.
6. Report keys and labels remain sourced from the retained Report catalog. Grouping should consume catalog metadata rather than copy the twelve keys into a second list.
7. Canonical source names remain sourced from the canonical Household source owner; the Hub must not create alternate source policy.
8. `fzf`, `gum`, and plain selectors present the same navigation relation. Selector-specific behavior must not become feature ownership.
9. Back navigation is explicit at every drill-down boundary, and returning from a child command returns to the immediately containing menu.
10. The Hub should optimize daily recognition and locality, not expose the repository architecture as its menu tree.
11. Choosing a write action should precede choosing its target whenever practical. The user should know why a list is being shown.

## Validated task walks

The information architecture was walked through against representative daily tasks before changing runtime shell code.

### Record a normal expense

```text
BQN Ledger
  -> Editor
    -> Journal
      -> Expense
```

No unrelated choice is encountered. This is a natural three-step path and remains the shortest ordinary writer path after entering the Hub.

### Actualize a Plan and replenish the next Plan

```text
BQN Ledger
  -> Editor
    -> Plans
      -> Finish / actualize / replenish
        -> select open Plan
```

The action is chosen before the Plan list appears. This is preferable to entering a generic Plan browser and then discovering available mutations.

The existing Plan finish owner decides the concrete finish and optional replenishment workflow. Plan completion does not perform Budget-sync; the Hub exposes no Budget-sync task.

### Close an Issue

```text
BQN Ledger
  -> Editor
    -> Issues
      -> Close Issue
        -> select open Issue
```

The open-Issue list is therefore a target selector for `Close Issue`, not a peer read-only feature beside it.

### Inspect upcoming obligations

```text
BQN Ledger
  -> Reports
    -> Activity
      -> Planned Payments
```

This walk exposed the main correction to the initial Editor design. `Browse upcoming Plans` would duplicate a read-only semantic task inside Editor. Upcoming-obligation inspection belongs in Reports; editing a particular Plan remains `Editor > Plans > Edit Plan`.

### Inspect balances and Envelope state

```text
BQN Ledger
  -> Reports
    -> Accounting
      -> Account Balances
```

and:

```text
BQN Ledger
  -> Reports
    -> Household
      -> Envelope & Backing
```

These are two distinct retained semantic reports, so the user returns only as far as the Reports group menu when moving between them. No new combined report or special Hub-owned dashboard is invented by this design.

### Open `actual.journal` directly

```text
BQN Ledger
  -> Source & System
    -> Open canonical source
      -> actual.journal
```

The path makes the authority change visible: this is direct source access, not a writer-backed Journal Editor operation.

### Run Household admission diagnostics

```text
BQN Ledger
  -> Source & System
    -> Household check
```

Diagnostics stay beside other source/system inspection rather than competing with daily record/report choices.

## Walkthrough conclusion

The three-way top level survives the task walk without requiring a cross-branch bounce for a single task.

The one design correction is important: **Editor is action-oriented, not browse-oriented.** Read-only Plan/Account/Issue inspection should not be duplicated there merely because editor commands can produce lists. Target selection remains available after an edit action is chosen.

The resulting mental model is:

```text
Editor          change admitted Household evidence
Reports         inspect semantic Household results
Source & System inspect or directly handle physical/system boundaries
```

This is now the preferred design baseline for a later `tools/bl` implementation.

## Existing actions that move under the new hierarchy

The current mixed domain/report entries would be separated as follows:

- `Accounts > Account Balances report` moves to `Reports > Accounting > Account Balances`.
- `Budget > Envelope & Backing report` moves to `Reports > Household > Envelope & Backing`.
- `Issues > Issues report` moves to `Reports > Activity > Issues`.
- general Journal history moves to `Reports > Activity > Recent Journal`; transaction selection needed for Reverse remains subordinate to `Editor > Journal > Reverse`.
- general Plan browsing moves to `Reports > Activity > Planned Payments`; target selection needed by Edit/Finish remains subordinate to those Editor actions.
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
- decide keyboard accelerators, colors, icons, preview geometry, or selector-specific decoration;
- create a new combined balances/Envelope dashboard.

Those should follow only after the information architecture itself is accepted.

## Implementation observation to preserve

The current Hub already states the correct architectural boundary: it owns navigation, selection, and presentation while accounting, admission, and publication remain in their existing owners. The drill-down rewrite should preserve that statement and reduce mixed responsibility rather than replacing it with a new command framework.

The next implementation step, when deliberately started, should therefore change only interactive navigation first. Direct command entry points should remain stable, and no BQN-native Phase 6 refactor should be smuggled into the UI rewrite.
