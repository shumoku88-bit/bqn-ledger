# Cross-cutting frontend reachability audit — 2026-08-17

## Scope

This audit follows the production BQN review and promoted-experiment retirement. It observes the current frontend graph without changing accounting, source, or writer meaning.

## Current entrypoints

### Canonical Household entrypoint

`tools/bl` is live and current.

With no command it enters `tools/household-surface`, the Calendar-first spatial frontend. With an explicit command it remains a direct router to established report/editor/tool owners.

The older description of `tools/bl` as an `Editor / Reports / Source & System` discovery hierarchy is no longer current. That hierarchy was removed during the Household surface cutover.

### Calendar-first spatial frontend

`tools/household-surface` is the primary spatial terminal surface.

It consumes:

```text
Home Calendar frame
+
HouseholdSurface Domain × Operation metadata
+
HouseholdSurface.Actions per selected cell
```

Raw key packets, alternate-screen drawing, cursor geometry, and selected-cell presentation remain shell concerns.

The primary surface intentionally does not depend on fzf or gum.

### Flat gum Command Palette

`tools/household-hub-gum` is also live and directly qualified.

It is not the retired hierarchical Command Hub. It is a flat searchable frontend over the current `HouseholdSurface.Actions` relation, with Calendar / Reports / Source & System utilities as sibling destinations.

This gives gum an independent current role. The question is therefore not “remove gum because the Calendar surface exists.” Both frontends consume the same logical action portfolio through different physical interaction shapes.

### Shared logical action dispatcher

`tools/household-action` validates an action key against `HouseholdSurface.Actions` and maps that logical key to the existing direct command/report owner.

Both current Household frontends now delegate selected logical actions through this dispatcher:

```text
Calendar spatial frontend
        \
         -> tools/household-action -> tools/bl / direct owners
        /
flat gum Command Palette
```

The Calendar surface no longer owns a second action-key -> command case table. It selects one admitted action key and passes the selected date and base directory to `tools/household-action`.

`check-household-surface.sh` now guards this boundary and rejects a direct `tools/bl`/`tools/edit` route table inside `run_logical_action`.

## Selector adapters

`tools/lib/ui-choice.sh` and `tools/lib/ui-preferences.sh` are live physical adapters.

They select one opaque input row through:

```text
auto
fzf
gum
plain
```

The helper does not interpret Account, Plan, Issue, report, or writer meaning. Nested/high-cardinality selectors may therefore keep fzf/gum/plain without making any selector backend the Household information architecture.

## Writer interaction helper

`tools/add-ui.sh` is live.

Its explicit modes are writer-interaction leaves invoked by direct routes and Household actions. Its no-mode `choose_mode` menu remains a standalone writer shortcut. That static writer menu is not the primary Household information architecture, but it duplicates part of the logical action portfolio and is now the next frontend duplication to review.

Do not replace it by blindly dumping all `HouseholdSurface.Actions`: the production action relation also contains Observe/report actions and uses logical keys such as `budget-move` / `issue-add` that intentionally differ from physical `add-ui` mode names.

The next question is narrower:

```text
Should the standalone writer-shortcut portfolio be projected from one current writer-action relation,
or is its separate compact menu still the clearest compatibility surface?
```

That decision must preserve explicit `add-ui` modes and direct editor commands regardless of the no-mode menu result.

## Retired `tui/` status directory

Before this audit, `tui/` contained no implementation at all, only `tui/README.md` dated 2026-06-29.

That note said the TUI was frozen, described `tools/bl` as the Command Hub, and linked to archived planning documents that no longer exist at those paths. It predated the Calendar-first surface, current logical action relation, flat gum palette, and shared dispatcher.

Keeping an implementation-shaped top-level `tui/` directory with only that stale note made the repository map less accurate. The note is retired. Current frontend architecture is documented by:

```text
docs/HOUSEHOLD_SURFACE_MATRIX_DESIGN-2026-08-16.md
docs/PRODUCTION_EDITOR_DIRECTION.md
this audit
```

Git history retains the old frozen-TUI decision as historical evidence.

## Current architecture

```text
                   HouseholdSurface
               Domain × Operation × Actions
                           |
          +----------------+----------------+
          |                                 |
Calendar spatial frontend             flat gum palette
 tools/household-surface              tools/household-hub-gum
          |                                 |
          +---------------+-----------------+
                          |
               tools/household-action
                          |
                      tools/bl
                          |
            existing direct report/editor owners
```

This is now the current logical action route. Physical frontends may differ without rebuilding command meaning.

## Decisions

- keep `tools/bl` as the canonical entrypoint/direct router;
- keep the Calendar-first surface as the primary spatial frontend;
- keep the flat gum palette as an optional current frontend;
- keep fzf/gum/plain nested selector adapters while they have independent physical roles;
- keep `tools/household-action` as the one logical action dispatcher for Household frontends;
- retire the stale `tui/README.md` status-only directory;
- review the standalone `add-ui` writer menu separately rather than conflating it with the full Household action relation.

## Next cursor

```text
standalone tools/add-ui.sh writer-menu duplication
```
