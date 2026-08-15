# Command Hub drill-down implementation — 2026-08-12

## Result

The accepted Command Hub information architecture is now implemented in `tools/bl` for the no-argument interactive Hub.

The top-level interaction is:

```text
Editor
Reports
Source & System
Exit
```

This implementation does not replace or rename the existing direct CLI routes. Commands such as `bl reports`, `bl plans list`, `bl accounts list`, `bl issues list`, `bl edit actual.journal`, and the direct report-key fallback retain their existing routing behavior.

## Editor

The interactive Editor now asks which Household evidence family will be changed, then which mutation is intended.

```text
Editor
  Journal
    Expense
    Income
    Transfer / move
    Multi-posting transaction
    Reverse with a compensating transaction

  Plans
    Add Plan
    Edit Plan date / amount
    Finish / actualize / replenish Plan
    Related Plan evidence

  Budget
    Add / move Budget

  Accounts
    Add Account

  Issues
    Add Issue
    Close Issue
```

General read-only browse leaves are deliberately absent. Mutation-specific target selection remains inside the established writer/editor UI after the action is chosen. `Related Plan evidence` remains as a bounded Plan-editor decision aid rather than a general list surface.

## Reports

The interactive Reports branch first selects a human-facing group:

```text
Household
Accounting
Activity
All reports
Sequential preview
```

The three groups map to the existing Report catalog categories `household`, `accounting`, and `operations`. `Activity` is only the human-facing label for `operations`.

The Hub does not own a second list of the twelve retained report keys. `report_group_lines` consumes `tools/report-section-metadata` and filters its category coordinate, so report keys and labels remain owned by the existing Report catalog/metadata path.

The direct `bl reports` selector remains the existing flat catalog selector. The new group drill-down is the no-argument Command Hub navigation only.

## Source & System

Raw canonical-source opening is now visibly separate from structured Editor actions:

```text
Source & System
  Open canonical source
  Household check
  Ledger / provenance inspection
  Dependency and source diagnosis
  Export canonical Journals to hledger
  Compact report summary
  Exact compact-key query (advanced)
  Repository development suite
```

`Open canonical source` drills into the existing canonical eight-file list. It still delegates to `$EDITOR`; it does not gain writer authority or alternate-source discovery.

## Qualification

`checks/check-command-hub-drilldown.sh` drives the real Hub under a pseudo-terminal with the plain selector and walks:

1. the top-level four-way hierarchy;
2. every Editor domain menu;
3. all three Report category groups;
4. Source & System and the canonical-source submenu.

The check protects these navigation laws:

- former domain categories do not remain at the top level;
- general browse/report leaves do not leak into Editor;
- all retained Report labels remain reachable through metadata-derived groups;
- Editor actions do not leak into Reports;
- the canonical eight-file source list is reachable only under Source & System in this walkthrough;
- Report grouping continues to consume `tools/report-section-metadata` category metadata rather than duplicating the twelve-key catalog.

The pre-existing Command Hub recovery check continues to qualify direct CLI routing, report execution, writer delegation, canonical-source restrictions, selector compatibility, legacy poison-source independence, and non-TTY behavior.

## Boundary

This UI implementation is separate from the BQN-native Phase 6 review. It does not resolve the Issue Editor duplication/mutation observations recorded in the BQN review queue and does not move that review cursor.
