# UI selector backend observation — 2026-08-13

## Status

Observation and migration guardrail only. This does not choose or remove gum, fzf, plain terminal input, native BQN UI, raylib, or any future frontend.

This follows the Home frontend-boundary observation and the shared Home `CellRelation` work. The purpose is to stop optional terminal-tool dependencies from spreading while the UI boundary is being made frontend-independent.

## Current finding

`gum` is not part of canonical Household semantics or configuration. Selector preference is local terminal presentation policy through `BL_SELECTOR=auto|fzf|gum|plain`.

Direct selector-backend ownership is nevertheless duplicated across four active shell UI surfaces:

- `tools/bl` — Command Hub menus;
- `tools/add-ui.sh` — daily-entry menus and text input;
- `tools/main-ui.sh` — report selector, including its specialized fzf preview path;
- `tools/plan-finish-replenish-ui.sh` — Plan finish/replenish choices and text input.

These files may currently name `gum` directly. New UI surfaces should not add a fifth direct owner.

## Why this matters

The dependency itself is not the architectural problem. The risk is that each workflow independently grows:

- backend discovery;
- fzf/gum/plain fallback policy;
- choice serialization;
- physical prompt behavior;
- label-to-semantic-key recovery;
- text-input fallback behavior.

If those responsibilities continue to spread, replacing gum later means changing several workflows and risks changing workflow semantics at the same time.

The desired direction is instead:

```text
semantic workflow / logical action
            |
            v
small physical UI adapter
      /      |      \
    fzf     gum    plain
```

A future native-BQN or raylib frontend should consume the same semantic workflow/action meaning without inheriting terminal selector contracts.

## Deliberate non-goal: one universal selector

The current selector uses are not all identical.

`tools/main-ui.sh` has a real specialized capability: fzf preview consumes report cache/status evidence while browsing. That should not be forced through a lowest-common-denominator chooser merely to remove a repeated `gum` token.

Likewise, candidate choice and free text input are different physical interactions and should not be collapsed into one generic widget abstraction.

Therefore the next migration should start with a pair of genuinely equivalent consumers, not with a universal `Widget`/`Renderer`/`Selector` framework.

## Recommended migration order

1. Freeze the current direct backend-owner set so new shell surfaces cannot copy another fzf/gum/plain switch.
2. Compare the ordinary `select_line` behavior in `tools/add-ui.sh` and `tools/plan-finish-replenish-ui.sh` and extract only the stable shared choice contract.
3. Move Command Hub ordinary menu selection onto that adapter if its `key<TAB>label` contract fits without semantic loss.
4. Keep report-preview specialization separate until a second real consumer demonstrates the same preview contract.
5. Treat free text input as a separate adapter only when its current duplicated behavior has been characterized.
6. After migration, the final direct `gum` references should live only in physical terminal adapters, not workflow owners.

## Boundary law

A selector backend may decide how a user physically chooses or enters a value. It must not decide what that value means.

In particular, backend code must not own:

- Household source parsing;
- accounting semantics;
- Plan/Issue lifecycle rules;
- Home date/marker semantics;
- report section meaning;
- writer authority;
- identity or provenance;
- exact arithmetic.

The stable target remains:

```text
one semantic meaning
one logical workflow/action vocabulary where sharing is real
replaceable physical UI adapters
```

Gum may remain useful. The architectural goal is that keeping, replacing, or removing it becomes a local frontend decision rather than a workflow rewrite.
